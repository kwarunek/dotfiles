#!/bin/bash
WS_DIR=${WS_DIR:-"/tmp/ws"}
CONTAINER_ENGINE=${CONTAINER_ENGINE:-"podman"}
WS_HOME_IN="/home/$USER/"


WS_CLAUDE_CONFIG_DIR_NAME='.claude-ws'

ws() {
    local dir=""
    local -a mount_args=()
    local -a network_args=()
    local cpu_millicores=1500
    local memory_mb=1024
    local pids_limit=256
    local cpus=""
    local llm=""
    local -a llm_args=()
    local bind_mode="ro"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                echo "Usage: ws [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -d DIR          Mount directory DIR to /mnt/DIR inside container (read-only)"
                echo "  -w              Mount the -d directory read-write (default: read-only)"
                echo "  --cpu MILLICORES Set container CPU limit in millicores (default: 1500)"
                echo "  --mem MB         Set container memory limit in MB (default: 1024)"
                echo "  --pids N         Set max processes/threads (default: 256)"
                echo "  -x              Run container without network"
                echo "  --llm           Mount ~/.claude, ~/.codex, ~/.copilot read-write into"
                echo "                  the image's own \$HOME (shared history + credentials)"
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
            --pids)
                if [[ -z "$2" ]]; then
                    echo "Error: --pids requires a value"
                    return 1
                fi
                if ! [[ "$2" =~ ^[0-9]+$ ]] || [[ "$2" -le 0 ]]; then
                    echo "Error: --pids expects a positive integer value"
                    return 1
                fi
                pids_limit="$2"
                shift 2
                ;;
            -x)
                network_args=(--network none)
                shift
                ;;
            -w)
                bind_mode="rw"
                shift
                ;;
            --llm)
                llm=1
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    local port
    while true; do
        port=$(shuf -i 10000-65000 -n 1)
        if ! ss -tuln | grep -q ":$port "; then
            break
        fi
    done

    if [[ -n "$dir" ]]; then
        local d
        d=$(realpath "$dir")
        mount_args+=(-v "$d:/mnt$d:$bind_mode")
    fi
    printf -v cpus "%d.%03d" "$((cpu_millicores / 1000))" "$((cpu_millicores % 1000))"

    local name
    name=$(random_name color)-$(random_name animal)

    mkdir -p "$WS_DIR/$name"

    mount_args+=(-v "$WS_DIR/$name:/workspace")

    local image="ws"
    local -a pull_args=()
    local -a userns_args=()
    if [[ "$CONTAINER_ENGINE" == "podman" ]]; then
        image="localhost/ws"
        pull_args=(--pull=never)
        userns_args=(--userns=keep-id)
    fi

    if [[ -n "$llm" ]]; then
        image="ws-llm"
        if [[ ${#network_args[@]} -gt 0 ]]; then
            echo "warning: -x disables networking, the agents will not be able to authenticate" >&2
        fi

        local chome="${WS_HOME_IN}"
        [[ -d "$HOME/$WS_CLAUDE_CONFIG_DIR_NAME" ]]  && llm_args+=(-v "$HOME/$WS_CLAUDE_CONFIG_DIR_NAME:$chome/$WS_CLAUDE_CONFIG_DIR_NAME")
        [[ -d "$HOME/.codex" ]]   && llm_args+=(-v "$HOME/.codex:$chome/.codex")
        [[ -d "$HOME/.copilot" ]] && llm_args+=(-v "$HOME/.copilot:$chome/.copilot")

        # local gh_cfg="${XDG_CONFIG_HOME:-$HOME/.config}/gh"
        # [[ -d "$gh_cfg" ]] && llm_args+=(-v "$gh_cfg:$chome/.config/gh")

        llm_args+=(-e "CLAUDE_CONFIG_DIR=$chome/$WS_CLAUDE_CONFIG_DIR_NAME")

        local v
        for v in ANTHROPIC_API_KEY OPENAI_API_KEY GITHUB_TOKEN GH_TOKEN; do
            [[ -n "${!v}" ]] && llm_args+=(-e "$v")
        done

        echo "llm: host configs mounted rw under $chome"
    fi

    if [[ ${#network_args[@]} -eq 0 && "$CONTAINER_ENGINE" == "podman" ]]; then
        network_args=(--network=slirp4netns:allow_host_loopback=false)
    fi

    echo "port $port $WS_DIR/$name mounted in /workspace"

    $CONTAINER_ENGINE run -it -h "$name" \
        --name "$name" \
        --cap-drop=ALL \
        --security-opt=no-new-privileges:true \
        --pids-limit="$pids_limit" \
        --ulimit nofile=65536:65536 \
        --memory="${memory_mb}m" --cpus="$cpus" \
        --user "$(id -u):$(id -g)" "${userns_args[@]}" --rm \
        "${pull_args[@]}" \
        -p "127.0.0.1:$port:$port" "${network_args[@]}" "${mount_args[@]}" "${llm_args[@]}" \
        "$image"
}
