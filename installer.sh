#!/usr/bin/env bash

cd ~
git clone https://github.com/kAlmAcetA/dotfiles.git &>/dev/null
cd dotfiles
git pull
git submodule init
git submodule update

cfgs=(bash vc vim)

init_bash_cfg (){
    echo "Init bash config"
    rm -rf ~/.bashrc
    rm -rf ~/.bash_functions
    rm -rf ~/.bash_aliases
    ln -s ~/dotfiles/.bashrc ~/.bashrc
    ln -s ~/dotfiles/.bash_aliases ~/.bash_aliases
    ln -s ~/dotfiles/.bash_functions ~/.bash_functions
    source ~/.bashrc
}

init_vc_cfg () {
    echo "Init VC config"
    rm -rf ~/.gitconfig
    ln -s ~/dotfiles/.gitconfig ~/.gitconfig
    rm -rf ~/.hgrc
    ln -s ~/dotfiles/.hgrc ~/.hgrc
}

init_vim_cfg () {
    echo "Init vim config"
    rm -rf ~/.vim
    rm -rf ~/.vimrc
    ln -s ~/dotfiles/.vim ~/.vim
    ln -s ~/dotfiles/.vimrc ~/.vimrc
}

for item in ${cfgs[*]}
do
    if [[ "$1 " != " " ]]; then
        if [[ $item == $1 ]]
        then
            init_${item}_cfg
            exit 0
        fi
    else
        read -p "Install $item config?[y/n] " -n 1 -r
        echo    # (optional) move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
           init_${item}_cfg
        fi
    fi
done
