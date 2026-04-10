#!/bin/bash

ws() {
    local dir=""
    local mount_arg=""
    local network_arg=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                echo "Usage: ws [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -d DIR          Mount directory DIR to /mnt/DIR inside container"
                echo "  -x              Run docker without network"
                echo "  -h, --help      Show this help message"
                return 0
                ;;
            -d)
                dir="$2"
                shift 2
                ;;
            -x)
                network_arg="--network none"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    # Find random free port
    local port
    while true; do
        port=$(shuf -i 10000-65000 -n 1)
        if ! ss -tuln | grep -q ":$port "; then
            break
        fi
    done

    # Setup mount if directory provided
    if [[ -n "$dir" ]]; then
        d=$(realpath "$dir")
        mount_arg="-v $d:/mnt$d"
    fi

    name=$(random_name color)-$(random_name animal)

    mkdir -p /tmp/ws/$name

    mount_arg="$mount_arg -v /tmp/$name:/home/workspace"

    echo "port $port workspace /tmp/$name"
    docker run -it -h $name --rm -p "$port:$port" $network_arg $mount_arg ws
}
