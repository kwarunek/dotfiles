#!/usr/bin/env bash
{

init_repo_cfg (){
    cd ~
    git clone https://github.com/kwarunek/dotfiles.git &>/dev/null
    cd dotfiles
    git pull
    git submodule init
    git submodule update
}


init_bash_cfg (){
    echo "Init bash config"
    rm ~/.screenrc ~/.bashrc ~/.bash_functions ~/.bash_aliases ~/.bash_profile ~/.bash_login ~/.profile
    ln -s ~/dotfiles/.bashrc ~/.bashrc
    ln -s ~/dotfiles/.profile ~/.profile
    ln -s ~/dotfiles/.screenrc ~/.screenrc
    ln -s ~/dotfiles/.bash_aliases ~/.bash_aliases
    ln -s ~/dotfiles/.bash_colors ~/.bash_colors
    ln -s ~/dotfiles/.bash_functions ~/.bash_functions
}

init_vc_cfg () {
    echo "Init VC config"
    rm -rf ~/.gitconfig ~/.hgrc
    ln -s ~/dotfiles/.gitconfig ~/.gitconfig
    ln -s ~/dotfiles/.hgrc ~/.hgrc
}

init_vim_cfg () {
    echo "Init vim config"
    rm -rf ~/.vim
    rm -rf ~/.vimrc
    ln -s ~/dotfiles/.vim ~/.vim
    ln -s ~/dotfiles/.vimrc ~/.vimrc
}

init_flake8_cfg () {
    echo "Flake8"
    pip3 install --user flake8 black
    mkdir -p ~/.config
    ln -s ~/dotfiles/.config/flake8 ~/.config/flake8
}

# optional
init_go_cfg () {
    echo "go"
    GO_VERSION=1.7.3
    rm -rf ~/go
    wget -O- wget https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz 2>/dev/null | tar xvz -C ~
    echo 'export GOROOT=$HOME/go' >> ~/.profile_local
    echo 'export PATH=$PATH:$GOROOT/bin' >> ~/.profile_local
    mkdir -p ~/workspace/go
    echo 'export GOPATH=$HOME/workspace/go' >> ~/.profile_local
}

init_asdf_cfg () {
   git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2
}

if [[ "$1 " -eq " " ]];
then
    init_repo_cfg
    init_bash_cfg
    init_vim_cfg
    init_flake8_cfg
    init_asdf_cfg

    # install repo config only for kwarunek
    if [[ "$USER" = "kwarunek" ]];
    then
        init_vc_cfg
    fi
else
    init_${1}_cfg
fi
}
