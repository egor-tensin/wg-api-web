#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
shopt -s inherit_errexit lastpipe

script_dir="$( dirname -- "${BASH_SOURCE[0]}" )"
script_dir="$( cd -- "$script_dir" && pwd )"
readonly script_dir

script_dir_ownership="$( stat -c '%u:%g' -- "$script_dir" )"
readonly script_dir_ownership

readonly server=10.13.13.1

fix_permissions() {
    chown -R -- "$script_dir_ownership" "$script_dir/example_config"
}

docker_build() {
    docker-compose build --force-rm --progress plain --pull "$@"
}

build_services() {
    echo ------------------------------------------------------------------
    echo Pull third-party images
    echo ------------------------------------------------------------------
    docker-compose pull wg api

    echo ------------------------------------------------------------------
    echo Build wg-api-web
    echo ------------------------------------------------------------------
    docker_build web

    echo ------------------------------------------------------------------
    echo Build peer1
    echo ------------------------------------------------------------------
    docker_build peer1

    echo ------------------------------------------------------------------
    echo docker-compose up
    echo ------------------------------------------------------------------
    docker-compose up -d

    sleep 5
}

ping_server() {
    echo ------------------------------------------------------------------
    echo Pinging the server
    echo ------------------------------------------------------------------
    ping -c 5 -W 3 "$server"
}

cleanup() {
    echo ------------------------------------------------------------------
    echo Cleaning up
    echo ------------------------------------------------------------------
    docker-compose down -v --remove-orphans
    fix_permissions
}

main() {
    cd -- "$script_dir"
    trap cleanup EXIT

    fix_permissions
    if ping_server; then
        echo "Should've failed to ping the server!" >&2
        exit 1
    fi
    build_services
    ping_server
    "$script_dir/../check_web.sh"
}

main
