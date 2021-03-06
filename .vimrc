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
set expandtab
set noshowmode
set nowildmenu
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
set ttimeout          " for key codes
set ttimeoutlen=10    " unnoticeable small value


" easier attainable leader
let mapleader = ","

nnoremap <F3> :set invpaste paste?<CR>

set pastetoggle=<F3>

" search - "very magic" - all special ch except [a-z0-9_]/i
"nnoremap / /\v
"vnoremap / /\v
" search end

" search - clear last highlight  
" nnoremap <leader><space> :noh<cr>

" invoke cmd without CTRL - common mistake
nnoremap ; :

" enable sudo force
cmap w!! w !sudo tee >/dev/null %

" trailing withspaces remover
nnoremap <leader>nw :%s/\s\+$//e<cr>:let @/=''<CR>
" ...version with no match err message
nnoremap <leader>w :%s/\s\+$//<cr>:let @/=''<CR>

" css sorter
nnoremap <leader>cssort ?{<CR>jV/^\s*\}?$<CR>k:sort<CR>:noh<CR>

" edit .vimrc
nnoremap <leader>ev <C-w><C-v><C-l>:e $MYVIMRC<cr>



" CTRL+A - select all
map <C-A> ggVG

" NERDTree toggle
map <F1> :set invcursorcolumn<CR>:IndentLinesToggle<CR>
map <F2> :NERDTreeToggle<CR>
map <F4> <leader>c<space>

" use arrow keys to move around buffers
nnoremap <silent> <Left>   :bn<CR>
nnoremap <silent> <Right>  :bp<CR>



" Bclose - close current buffer, preserve layout
map <Leader>bc :Bclose<CR>
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
" Bclose end

" indentLine
let g:indentLine_fileType = ['yml', 'yaml', 'sls', 'conf']

" NERDTree options
let g:NERDTreeChristmasTree = 1
let g:NERDTreeCaseSensitiveSort = 1
let g:NERDTreeQuitOnOpen = 1
let g:NERDTreeWinPos = 'left'
let g:NERDTreeWinSize = 50
let g:NERDTreeShowBookmarks = 1
let g:NERDTreeShowHidden=0
let g:NERDTreeIgnore=['\.pyc','\~$','\.swo$','\.swp$','\.bzr']

let python_highlight_all=1

" airline top tabline
let g:airline#extensions#tabline#enabled = 1

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


" hihglight trailing whitespaces
highlight BadWhitespace ctermbg=red guibg=red
au BufRead,BufNewFile *.json,*.js,*.yaml,*.php,*.css,*.less,*.scss,*.xml,*.pm,*.rb,*.inc,*.py,*.pyw match BadWhitespace /^\t\+/
au BufRead,BufNewFile *.json,*.js,*.yaml,*.php,*.css,*.less,*.scss,*.xml,*.pm,*.rb,*.inc,*.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/
" highlight


" fugitive tweaks
:command -nargs=+ Ggr execute 'Ggrep' <q-args> | cw

" global options for py (incl ctags)
au BufRead,BufNewFile *.py,*.pyw set tags+=$HOME/.vim/tags/python.ctags
au BufNewFile *.py,*.pyw,*.c,*.h,*.pm,*.sh set fileformat=unix

if has("autocmd")

    autocmd FileType python set omnifunc=pythoncomplete

    " js 2
    autocmd Filetype javascript setlocal ts=2 sts=2 sw=2
    autocmd FileType make setlocal ts=8 sts=8 sw=8 noexpandtab
    autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab cursorcolumn

    " linters flake and js
    " autocmd BufWritePost *.py call Flake8()
    autocmd FileType python noremap <buffer> <F7> :call Flake8()<CR>
    autocmd FileType javascript noremap <buffer> <F7> :JSHint<CR> 

    autocmd BufNewFile,BufRead *.rss setfiletype xml

endif

set tags=tags;/

au BufRead,BufNewFile *.md set filetype=markdown

let g:jsx_ext_required = 0

syntax on
filetype indent on
filetype on
filetype plugin on

" highlight coloumn limit 120ch
highlight ColorColumn ctermbg=236
set colorcolumn=120
