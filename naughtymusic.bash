#!/usr/bin/bash
set -eu -o pipefail

declare +x host="${1:-127.0.0.1}"
declare +x port="${2:-6600}"
declare +x password

read -rsp 'Password: ' password || exit 1

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

    while true; do
        send-and-wait "currentsong"
        echo "Now playing: ${result[file:]}"
        notify "Playing" "${result[file:]}"
        send-and-wait "idle"
    done
}

wait-result()
{
    declare +x key
    declare +x value
    result=()
    while read -r key value; do
        result["$key"]="$value"
        printf "[%s] = [%s]\n" "$key" "$value" >&2
        [[ "$key" == "OK" ]] && return
        [[ "$key" == "ACK" ]] && {
            printf "Failure: %s\n" "$value"
            return 1
        }
    done <&42
}

send-and-wait()
{
    printf "%s %s\n" "-- SEND --" "$*" >&2
    echo "$*" >&42
    wait-result
}

declare +x notify_id=""
notify()
{
    declare +x -a args=()
    [[ -z "$notify_id" ]] || args+=(-r "$notify_id")
    echo notify-send "${args[@]}" -p "$@" >&2
    notify_id="$(notify-send "${args[@]}" -p "$@")"
}

main "$@"

