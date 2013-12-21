filetype off

execute pathogen#infect()

set nobackup
set nowritebackup
set autochdir
set matchpairs+=<:>
set noswapfile
set tabstop=4
set shiftwidth=4
set nocompatible
set softtabstop=4
set autoindent
set smarttab
set showmode
set report=0
set viminfo='1000,f1,:1000,/1000,<1000,s100
set directory=$HOME/.vim/swapfiles,/var/tmp,/tmp,.
set history=1000
set undolevels=1000
set confirm
set updatetime=1500
set encoding=utf-8
set termencoding=utf-8
set noerrorbells visualbell t_vb=
set background=dark
set hlsearch
set ignorecase
set smartcase
set hidden
set laststatus=2
set number           " Show Line Numbers
set numberwidth=4      " Width value of the Line Number Column
set ruler
set showmatch          " Shows matching brackets when text indicator is over them
set scrolloff=5        " Show 5 lines of context around the cursor
set cursorline
set showcmd
set ttyfast            " Improves redrawing for newer computers
set backspace=indent,eol,start
set gdefault

nnoremap / /\v
vnoremap / /\v
nnoremap <leader><space> :noh<cr>
nnoremap ; :

let mapleader = ","
nnoremap <leader>nw :%s/\s\+$//e<cr>:let @/=''<CR>
nnoremap <leader>cssort ?{<CR>jV/^\s*\}?$<CR>k:sort<CR>:noh<CR>
nnoremap <leader>w :%s/\s\+$//<cr>:let @/=''<CR>
nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>
" nnoremap <leader>ct |NERDComToggleComment|
" vnoremap <leader>ct |NERDComToggleComment|
map <C-A> ggVG
map <F2> :NERDTreeToggle<CR>
nnoremap <silent> <Left>   :bn<CR>
nnoremap <silent> <Right>  :bp<CR>
map <F1> :call ToggleBg()<CR>
function! ToggleBg()
    if &background == 'dark'
	set bg=light
    else
        set bg=dark
    endif
endfunc
map <Leader>bc :Bclose<CR>
let g:NERDTreeChristmasTree = 1
let g:NERDTreeCaseSensitiveSort = 1
let g:NERDTreeQuitOnOpen = 1
let g:NERDTreeWinPos = 'left'
let g:NERDTreeWinSize = 50
let g:NERDTreeShowBookmarks = 1
let g:NERDTreeShowHidden=0
let g:NERDTreeIgnore=['\.pyc','\~$','\.swo$','\.swp$','\.git','\.hg','\.svn','\.bzr']
let python_highlight_all=1
" let g:syntastic_auto_jump = 1
" let g:syntastic_mode_map = { 'mode': 'active',
"                               \ 'active_filetypes': ['yaml','json'],
"                               \ 'passive_filetypes': [] }
"let g:syntastic_python_checkers = ['flake8']
"let g:syntastic_json_checkers = ['jsonlint']
"let g:syntastic_yaml_checkers = ['jsyaml']
"let g:syntastic_php_checkers = ['php']
if $TERM =~ "^xterm*"
    set t_Co=256
    colorscheme gummybears
elseif $TERM =~ "^screen*"
    set t_Co=256
    colorscheme gummybears
elseif $TERM =~ "^rxvt*"
    set t_Co=88
    colorscheme pablo
elseif $TERM =~ "^linux*"
    set t_Co=8
    colorscheme vividchalk
else
    set t_Co=16
    colorscheme pablo
endif

try
    set switchbuf=usetab
    set stal=2
catch
endtry

command! Bclose call <SID>BufcloseCloseIt()
function! <SID>BufcloseCloseIt()
	let l:currentBufNum = bufnr("%")
	let l:alternateBufNum = bufnr("#")
	if buflisted(l:alternateBufNum)
		buffer #
	else
		bnext
	endif
	if bufnr("%") == l:currentBufNum
		new
	endif
	if buflisted(l:currentBufNum)
		execute("bdelete! ".l:currentBufNum)
	endif
endfunction
highlight BadWhitespace ctermbg=red guibg=red
au BufRead,BufNewFile *.json,*.js,*.yaml,*.php,*.css,*.less,*.scss,*.xml,*.pm,*.rb,*.inc,*.py,*.pyw match BadWhitespace /^\t\+/
au BufRead,BufNewFile *.json,*.js,*.yaml,*.php,*.css,*.less,*.scss,*.xml,*.pm,*.rb,*.inc,*.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/
au BufRead,BufNewFile *py,*pyw,*.c,*.h set tabstop=8
au BufRead,BufNewFile *.py,*pyw set shiftwidth=4
au BufRead,BufNewFile *.py,*.pyw set expandtab
au BufRead,BufNewFile *.py,*.pyw set tags+=$HOME/.vim/tags/python.ctags
au BufNewFile *.py,*.pyw,*.c,*.h set fileformat=unix
au BufRead,BufNewFile *.md set filetype=markdown

autocmd FileType python set omnifunc=pythoncomplete
autocmd BufWritePost *.py call Flake8()

syntax on
filetype indent on
filetype on
filetype plugin on


