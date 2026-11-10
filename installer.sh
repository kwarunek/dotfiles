#!/usr/bin/env bash

setup_link() {
    local fname="$1"
    [[ -z "$fname" ]] && { echo "Error: empty filename"; return 1; }
    unlink "${HOME}/${fname}" 2>/dev/null || rm -rf "${HOME}/${fname}"
    mkdir -p "$(dirname "${HOME}/${fname}")"
    ln -s "${HOME}/dotfiles/${fname}" "${HOME}/${fname}"
}

init_repo_cfg (){
    cd ~
    git clone https://codeberg.org/kwarunek/dotfiles.git &>/dev/null
    cd dotfiles
    git pull
    git submodule init
    git submodule update
}

init_nvim_cfg (){
    echo "Init nvim"
    setup_link ".config/nvim"
    grep -qxF "alias vi=nvim" ~/.bash_local_aliases 2>/dev/null || echo "alias vi=nvim" >> ~/.bash_local_aliases
}

init_base_cfg (){
    echo "Init base config"

    # bash
    setup_link .bashrc
    setup_link .bash_aliases
    setup_link .bash_cache.d
    setup_link .bash_colors
    setup_link .bash_functions
    setup_link .bash_functions.d
    setup_link .bash_profile
    setup_link .bash-preexec.sh
    setup_link .config/atuin
    setup_link .config/bat
    setup_link .config/flake8
    setup_link .config/keepassxc

    # sway on wayland
    setup_link .config/sway
    setup_link .config/waybar
    setup_link .config/foot
    setup_link .config/kanshi
    setup_link .config/fuzzel

    # i3 on x11
    setup_link .config/i3
    setup_link .config/rofi
    setup_link .config/lxterminal

    setup_link .config/containers
    setup_link .config/starship.toml
    setup_link .config/tmux
    setup_link .aws/cli/alias

    setup_link .config/ws

    # k8s
    setup_link .kubectl_aliases

    # common
    setup_link .profile
    setup_link .curlrc
    setup_link .screenrc

    # psql
    mkdir -p ~/.psql_history.d
    setup_link .psqlrc
}

init_vc_cfg () {
    echo "Init VC config"
    setup_link .gitconfig
    setup_link .hgrc
}

init_vim_cfg () {
    echo "Init vim config"
    setup_link .vim
    setup_link .vimrc
}

# ackstile (MCP approval gateway, see README.md): ~/.ackstile is a real
# directory (700), not a link to the checkout. Only the versioned parts are
# linked one by one: config/config.yaml and automations/. Everything local
# and secret (config/env, config/tls/, config/automations/<name>/, data/)
# is created next to them as plain 700 directories, so a secret can never
# end up inside ~/dotfiles, which is a public repo. The binary, the systemd
# unit and /etc/hosts come from ackstile's `make install`; only the unit's
# PATH drop-in is linked from here.
init_ackstile_cfg () {
    echo "Init ackstile config"
    local root="${HOME}/.ackstile" dir name example conf f

    if [[ -L "$root" ]]; then
        echo "Error: $root is a symlink; make it a real directory first (local secrets must stay outside ~/dotfiles)"
        return 1
    fi
    (
        umask 077
        mkdir -p "$root/config/tls" "$root/config/automations" "$root/data"
        for dir in "${HOME}"/dotfiles/.ackstile/automations/*/; do
            mkdir -p "$root/config/automations/$(basename "$dir")"
        done
    )
    chmod 700 "$root" "$root/config" "$root/config/tls" "$root/config/automations" \
        "$root"/config/automations/*/ "$root/data"

    # A regular file or directory in place of a link (e.g. config.yaml from
    # `make install`) is kept as *.orig instead of being removed by setup_link.
    for f in .ackstile/config/config.yaml .ackstile/automations; do
        if [[ -e "${HOME}/$f" && ! -L "${HOME}/$f" ]]; then
            mv -n "${HOME}/$f" "${HOME}/$f.orig"
            if [[ -e "${HOME}/$f" && ! -L "${HOME}/$f" ]]; then
                echo "skipped ~/$f: ~/$f.orig already exists, move one of them away"
                continue
            fi
            echo "kept old ~/$f as ~/$f.orig"
        fi
        setup_link "$f"
    done
    # PATH for host automations (system python3 before the asdf shims)
    setup_link .config/systemd/user/ackstile.service.d/path.conf

    # Local config of automations (real AWS profiles, cluster contexts):
    # seeded once from the versioned examples, never overwritten.
    for example in "${HOME}"/dotfiles/.ackstile/automations/*/*.example; do
        [[ -f "$example" ]] || continue
        name="$(basename "$(dirname "$example")")"
        conf="$root/config/automations/$name/$(basename "$example" .example)"
        [[ -e "$conf" ]] && continue
        install -m600 "$example" "$conf" && echo "created $conf from the example, edit it"
    done

    # Old layouts: hints only, data is never moved here.
    [[ -L "${HOME}/automation" || -e "${HOME}/automation" ]] \
        && echo "hint: ~/automation is the old location of the automations; remove it (now ~/.ackstile/automations)"
    [[ -d "${HOME}/.automation" ]] \
        && echo "hint: move local automation config: ~/.automation/<name>/* -> ~/.ackstile/config/automations/<name>/ (chmod 600), then remove ~/.automation"
    [[ -e "${HOME}/.config/ackstile/env" ]] \
        && echo "hint: move ~/.config/ackstile/env -> ~/.ackstile/config/env (chmod 600)"
    [[ -d "${HOME}/.config/ackstile/tls" ]] \
        && echo "hint: move ~/.config/ackstile/tls -> ~/.ackstile/config/tls (keep the CA: agents and the browser trust it)"
    [[ -e "${HOME}/.local/share/ackstile/ackstile.db" ]] \
        && echo "hint: systemctl --user stop ackstile; mv ~/.local/share/ackstile/ackstile.db* ~/.ackstile/data/"
    [[ -L "${HOME}/ackstile" || -d "${HOME}/ackstile" ]] \
        && echo "hint: ~/ackstile is the old root; move env, tls/, automations/<name>/ and the database into ~/.ackstile, then remove it"
    for f in layout.conf pam.conf; do
        [[ -e "${HOME}/.config/systemd/user/ackstile.service.d/$f" ]] \
            && echo "hint: remove the old drop-in ~/.config/systemd/user/ackstile.service.d/$f, then systemctl --user daemon-reload"
    done

    command -v ackstile >/dev/null || [[ -x "${HOME}/.local/bin/ackstile" ]] \
        || echo "hint: install the binary and the systemd unit: make -C <ackstile checkout> install"
    getent hosts ackstile.local >/dev/null \
        || echo "hint: echo '127.0.0.1 ackstile.local mcp.ackstile.local' | sudo tee -a /etc/hosts"
    return 0
}

init_asdf_cfg () {
    ASDF_DIR=~/".asdf"
    ASDF_VERSION='v0.14.1'
    if [ -d "$ASDF_DIR" ]; then
        git -C $ASDF_DIR checkout $ASDF_VERSION
    else
        git clone https://github.com/asdf-vm/asdf.git $ASDF_DIR --branch $ASDF_VERSION
    fi

}

if [ -z "$1" ]; then
    git rev-parse --is-inside-work-tree &>/dev/null || init_repo_cfg
    init_base_cfg
    init_vim_cfg
    init_asdf_cfg
    # install repo config only for kwarunek
    if [[ "$USER" = "kwarunek" ]]; then
        init_vc_cfg
    fi
else
    case "$1" in
        base|vim|nvim|vc|asdf|ackstile) init_${1}_cfg ;;
        *) echo "Unknown target: $1"; exit 1 ;;
    esac
fi
