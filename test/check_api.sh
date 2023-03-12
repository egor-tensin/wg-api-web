#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
shopt -s inherit_errexit lastpipe

run_curl() {
    curl -sS -D - --connect-timeout 3 http://192.168.177.1:1234/ "$@"
}

run_curl_api() {
    run_curl -H 'Content-Type: application/json' "$@"
}

call_api_method() {
    local method
    for method; do
        echo ------------------------------------------------------------------
        echo "Checking API method: $method"
        echo ------------------------------------------------------------------
        run_curl_api -d '{"jsonrpc": "2.0", "method": "'"$method"'", "params": {}}'
    done
}

check_api() {
    call_api_method ListPeers
    call_api_method GetDeviceInfo
}

main() {
    check_api
}

main "$@"
