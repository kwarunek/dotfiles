#!/usr/bin/env sh

cd ~
git clone https://github.com/kAlmAcetA/dotfiles.git &>/dev/null
cd dotfiles
git pull
git submodule init
git submodule update


case $1 in
    "bash")
        rm -rf ~/.bashrc
        rm -rf ~/.bash_functions
        rm -rf ~/.bash_aliases
        ln -s ~/dotfiles/.bashrc ~/.bashrc
        ln -s ~/dotfiles/.bash_aliases ~/.bash_aliases
        ln -s ~/dotfiles/.bash_functions ~/.bash_functions
        source ~/.bashrc
        ;;
    "git")
        rm -rf ~/.gitconfig
        ln -s ~/dotfiles/.gitconfig ~/.gitconfig
        ;;
    *)  # always install vim's config
        rm -rf ~/.vim
        rm -rf ~/.vimrc
        ln -s ~/dotfiles/.vim ~/.vim
        ln -s ~/dotfiles/.vimrc ~/.vimrc
        ;;
esac

