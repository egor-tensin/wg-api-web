#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
shopt -s inherit_errexit lastpipe

readonly base_url='http://127.0.0.1:8090/'

run_curl() {
    curl -sS -D - --connect-timeout 3 "$@"
}

call_web_method() {
    local method
    for method; do
        echo ------------------------------------------------------------------
        echo "Checking /api/$method"
        echo ------------------------------------------------------------------
        run_curl -- "$base_url/api/$method"
    done
}

check_web() {
    call_web_method ListPeers
    call_web_method GetDeviceInfo
}

main() {
    check_web
}

main
