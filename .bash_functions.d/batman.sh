batman() {
    MANPAGER="sh -c 'col -bx | bat -l man -p'"  man $@
}
