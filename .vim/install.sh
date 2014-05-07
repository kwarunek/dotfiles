#!/bin/bash


sudo pip install flake8

#curl -Sso ~/.vim/autoload/pathogen.vim \
#    https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim
curl -sSL https://get.rvm.io | bash -s stable --ruby
curl https://raw.githubusercontent.com/creationix/nvm/v0.6.1/install.sh | sh
ctags -R -f ~/.vim/tags/python.ctags /usr/lib/python2.7
sudo npm install -g jshint
