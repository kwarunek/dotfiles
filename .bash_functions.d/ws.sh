#!/bin/bash
WS_DIR=${WS_DIR:-"/tmp/ws"}

ws() {
    local dir=""
    local mount_arg=""
    local network_arg=""
    local cpu_millicores=1500
    local memory_mb=1024
    local cpus=""


    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                echo "Usage: ws [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -d DIR          Mount directory DIR to /mnt/DIR inside container"
                echo "  --cpu MILLICORES Set container CPU limit in millicores (default: 1500)"
                echo "  --mem MB         Set container memory limit in MB (default: 1024)"
                echo "  -x              Run docker without network"
                echo "  -h, --help      Show this help message"
                return 0
                ;;
            -d)
                if [[ -z "$2" ]]; then
                    echo "Error: -d requires a directory argument"
                    return 1
                fi
                dir="$2"
                shift 2
                ;;
            --cpu)
                if [[ -z "$2" ]]; then
                    echo "Error: --cpu requires a millicores value"
                    return 1
                fi
                if ! [[ "$2" =~ ^[0-9]+$ ]] || [[ "$2" -le 0 ]]; then
                    echo "Error: --cpu expects a positive integer millicores value"
                    return 1
                fi
                cpu_millicores="$2"
                shift 2
                ;;
            --mem)
                if [[ -z "$2" ]]; then
                    echo "Error: --mem requires a memory value in MB"
                    return 1
                fi
                if ! [[ "$2" =~ ^[0-9]+$ ]] || [[ "$2" -le 0 ]]; then
                    echo "Error: --mem expects a positive integer MB value"
                    return 1
                fi
                memory_mb="$2"
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
    printf -v cpus "%d.%03d" "$((cpu_millicores / 1000))" "$((cpu_millicores % 1000))"

    name=$(random_name color)-$(random_name animal)

    mkdir -p "$WS_DIR/$name"

    mount_arg="$mount_arg -v $WS_DIR/$name:/workspace"

    echo "port $port $WS_DIR/$name mounted in /workspace"
    docker run -it -h "$name" \
        --cap-drop=ALL \
        --security-opt=no-new-privileges:true \
        --pids-limit=256 \
        --memory="${memory_mb}m" --cpus="$cpus" \
        --user "$(id -u):$(id -g)" --rm \
        -p "$port:$port" $network_arg $mount_arg \
        ws
}
