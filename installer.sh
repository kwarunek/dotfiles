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
    ln -s ~/dotfiles/.bash_functions ~/.bash_functions
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

init_flake8_cfg () {
    echo "Flake8"
    pip install flake8
    mkdir -p ~/.config
    ln -s ~/dotfiles/.config/flake8 ~/.config/flake8
}

init_nvm_cfg () {
    echo "nvm"
    rm -rf ~/.nvm
    git clone https://github.com/creationix/nvm.git ~/.nvm && cd ~/.nvm && git checkout `git describe --abbrev=0 --tags`
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.profile_local
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >>  ~/.profile_local
}

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

if [[ "$1 " -eq " " ]];
then
    init_repo_cfg
    init_bash_cfg
    init_vc_cfg
    init_vim_cfg
    init_flake8_cfg
    init_go_cfg
    init_nvm_cfg
else
    init_${1}_cfg
fi
}
