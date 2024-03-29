#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
shopt -s inherit_errexit lastpipe

script_dir="$( dirname -- "${BASH_SOURCE[0]}" )"
script_dir="$( cd -- "$script_dir" && pwd )"
readonly script_dir

base_dir="$( mktemp -d )"
readonly base_dir

readonly subnet_base=192.168.166
ip_counter=1
port_counter=561

add_device() {
    local name
    for name; do
        local dir
        dir="$base_dir/devices/$name"
        mkdir -p -- "$dir"

        local ip
        ip="$subnet_base.$ip_counter"
        ip_counter=$((ip_counter + 1))
        echo "$ip" > "$dir/ip"

        local port
        port="$port_counter"
        port_counter=$((port_counter + 1))
        echo "$port" > "$dir/port"

        wg genkey | tee "$dir/private" | wg pubkey > "$dir/public"
        ip link add dev "$name" type wireguard
        ip addr add "$ip/24" dev "$name"
        wg set "$name" private-key "$dir/private"
        wg set "$name" listen-port "$port"
    done
}

connect_devices() {
    if [ "$#" -ne 2 ]; then
        echo "usage: ${FUNCNAME[0]} DEV1 DEV2" >&2
        return 1
    fi

    local dev1="$1"
    local dev2="$2"

    local dev1_dir
    dev1_dir="$base_dir/devices/$dev1"
    local dev2_dir
    dev2_dir="$base_dir/devices/$dev2"

    local pubkey1
    pubkey1="$( cat -- "$dev1_dir/public" )"
    local port
    port="$( cat -- "$dev1_dir/port" )"
    local pubkey2
    pubkey2="$( cat -- "$dev2_dir/public" )"
    local ip
    ip="$( cat -- "$dev2_dir/ip" )"

    wg set "$dev1" peer "$pubkey2" allowed-ips "$ip/32"
    wg set "$dev2" peer "$pubkey1" allowed-ips "$subnet_base.0/24" endpoint "127.0.0.1:$port" persistent-keepalive 25
}

up_device() {
    local name
    for name; do
        ip link set "$name" up
    done
}

show_device() {
    local name
    for name; do
        echo ------------------------------------------------------------------
        echo "Device: $name"
        echo ------------------------------------------------------------------
        wg show "$name"
        echo
    done
}

add_devices() {
    add_device server
    add_device client1
    add_device client2
    add_device client3
    connect_devices server client1
    connect_devices server client2
    connect_devices server client3
    up_device server client1 client2 client3
    sleep 5
    show_device server client1 client2 client3
}

build_services() {
    echo ------------------------------------------------------------------
    echo Pull third-party images
    echo ------------------------------------------------------------------
    docker-compose pull api

    echo ------------------------------------------------------------------
    echo Build wg-api-web
    echo ------------------------------------------------------------------
    docker-compose build --force-rm --progress plain --pull web

    echo ------------------------------------------------------------------
    echo docker-compose up
    echo ------------------------------------------------------------------
    WG_IFACE=server docker-compose up -d
}

cleanup() {
    echo ------------------------------------------------------------------
    echo Cleaning up
    echo ------------------------------------------------------------------

    if [ -d "$base_dir/devices" ]; then
        local name
        find "$base_dir/devices" -mindepth 1 -maxdepth 1 -type d -printf '%P\0' \
                | while IFS= read -d '' -r name; do
            echo "Removing device: $name"
            ip link delete "$name" type wireguard || true
        done
    fi

    echo "Removing $base_dir"
    rm -rf -- "$base_dir"

    echo 'Showing the latest container logs...'
    docker-compose logs --tail 25

    echo "Bringing down containers..."
    docker-compose down -v --remove-orphans
}

main() {
    cd -- "$script_dir/.."
    trap cleanup EXIT

    add_devices
    build_services
    "$script_dir/../check_api.sh"
    "$script_dir/../check_web.sh"
}

main "$@"
