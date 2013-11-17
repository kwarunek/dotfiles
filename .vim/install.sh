#!/bn/bash


sudo pip install flake8
mkdir -p ~/.vim/autoload ~/.vim/bundle ~/.vim/tags  ~/.vim/colors; \
curl -Sso ~/.vim/autoload/pathogen.vim \
    https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim
ctags -R -f ~/.vim/tags/python.ctags /usr/lib/python2.7
cd ~/.vim/bundle
git clone https://github.com/nvie/vim-flake8.git
git clone https://github.com/scrooloose/nerdtree.git
git clone https://github.com/scrooloose/nerdcommenter.git
cd /tmp
git clone https://github.com/jelera/vim-gummybears-colorscheme.git vimgummybears
cp -r vimgummybears/colors/* ~/.vim/colors
git clone https://github.com/tpope/vim-vividchalk.git vividchalk
cp -r vividchalk/colors/* ~/.vim/colors
