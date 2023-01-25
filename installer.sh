#!/usr/bin/env bash
{

setup_link() {
    fname=$1
    rm -f ~/$fname
    ln -s ~/dotfiles/$fname ~/$fname
}

init_repo_cfg (){
    cd ~
    git clone https://github.com/kwarunek/dotfiles.git &>/dev/null
    cd dotfiles
    git pull
    git submodule init
    git submodule update
}


init_base_cfg (){
    echo "Init base config"
    
    # bash
    setup_link .bashrc
    setup_link .bash_aliases
    setup_link .bash_colors
    setup_link .bash_functions

    # k8s
    setup_link .kubectl_aliases

    # common
    setup_link .profile
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

init_asdf_cfg () {
    ASDF_DIR=~/".asdf"
    ASDF_VERSION='v0.11.1'
    if [ -d "$ASDF_DIR" ]; then
        git -C $ASDF_DIR pull origin master
        git -C $ASDF_DIR checkout $ASDF_VERSION
    else
        git clone https://github.com/asdf-vm/asdf.git $ASDF_DIR --branch $ASDF_VERSION
    fi

}

if [[ "$1 " -eq " " ]];
then
    init_repo_cfg
    init_base_cfg
    init_vim_cfg
    init_asdf_cfg

    # install repo config only for kwarunek
    if [[ "$USER" = "kwarunek" ]]; then
        init_vc_cfg
    fi
else
    init_${1}_cfg
fi
}
