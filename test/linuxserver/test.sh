#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
shopt -s inherit_errexit lastpipe

script_dir="$( dirname -- "${BASH_SOURCE[0]}" )"
script_dir="$( cd -- "$script_dir" && pwd )"
readonly script_dir

build_services() {
    echo ------------------------------------------------------------------
    echo Pull third-party images
    echo ------------------------------------------------------------------
    docker-compose pull wg api

    echo ------------------------------------------------------------------
    echo Build wg-api-web
    echo ------------------------------------------------------------------
    docker-compose build --force-rm --progress plain --pull web

    echo ------------------------------------------------------------------
    echo docker-compose up
    echo ------------------------------------------------------------------
    docker-compose up -d
}

cleanup() {
    echo ------------------------------------------------------------------
    echo Cleaning up
    echo ------------------------------------------------------------------
    docker-compose down -v --remove-orphans
}

main() {
    cd -- "$script_dir"
    trap cleanup EXIT

    build_services
    sleep 3
    "$script_dir/../check_web.sh"
}

main
