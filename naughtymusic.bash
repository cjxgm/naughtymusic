#!/usr/bin/bash
set -eu -o pipefail

declare +x host="${1:-127.0.0.1}"
declare +x port="${2:-6600}"
declare +x password

read -rp 'Password: ' password || exit 1

exec 42<>"/dev/tcp/$host/$port"
declare +x -A result

main()
{
    wait-result
    echo Connected
    [[ -z "$password" ]] || {
        send-and-wait "password $password"
        echo Authenticated
    }
}

wait-result()
{
    declare +x key
    declare +x value
    result=()
    while read -r key value; do
        result["$key"]="$value"
        [[ "$key" == "OK" ]] && return
        [[ "$key" == "ACK" ]] && {
            printf "Failure: %s\n" "$value"
            return 1
        }
    done <&42
}

send-and-wait()
{
    echo "$*" >&42
    wait-result
}

main "$@"

