# bash completion for ws (ws/bin/ws)

_ws() {
    local cur=${COMP_WORDS[COMP_CWORD]} prev=${COMP_WORDS[COMP_CWORD-1]}
    local type=container sub="" others=0 i word

    # What is already on the line: -t TYPE, a vmm subcommand, other arguments.
    for ((i = 1; i < COMP_CWORD; i++)); do
        word=${COMP_WORDS[i]}
        if [[ $word == -t ]]; then
            type=${COMP_WORDS[i+1]}
            ((i++))
        elif [[ -z $sub && $others -eq 0 && ( $word == build || $word == cleanup ) ]]; then
            sub=$word
        else
            ((others++))
        fi
    done

    case $prev in
        -t)
            mapfile -t COMPREPLY < <(compgen -W "container vmm" -- "$cur")
            return
            ;;
        -d)
            compopt -o filenames
            mapfile -t COMPREPLY < <(compgen -d -- "$cur")
            return
            ;;
        --kernel)
            compopt -o filenames
            mapfile -t COMPREPLY < <(compgen -f -- "$cur")
            return
            ;;
        --cpu|--mem|--pids|--free|--image)
            return
            ;;
    esac

    local words
    case $sub in
        build) words="--llm --image --free --kernel -h" ;;
        cleanup) words="" ;;
        *)
            words="-t -d -w --cpu --mem --pids -x --llm -h"
            # Subcommands of ws-vmm.py must come first (only -t may precede them).
            [[ $type == vmm && $others -eq 0 ]] && words+=" build cleanup"
            ;;
    esac
    mapfile -t COMPREPLY < <(compgen -W "$words" -- "$cur")
}

complete -F _ws ws
