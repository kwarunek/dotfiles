
au BufRead,BufNewFile *py,*pyw,*.c,*.h set tabstop=8
au BufRead,BufNewFile *.py,*pyw set shiftwidth=4
au BufRead,BufNewFile *.py,*.pyw set expandtab

set nobackup
set nowritebackup
set autochdir
set matchpairs+=<:>
set noswapfile
set tabstop=4
set shiftwidth=4
set softtabstop=4
set autoindent
set smarttab
set report=0
" marks: 1000 files, history lines: 1000 lines, search queries: 1000 patterns, registers: 1000
set viminfo='1000,f1,:1000,/1000,<1000,s100
" Swap directory to store temporary files
set directory=$HOME/.vim/swapfiles,/var/tmp,/tmp,.
set history=1000
set undolevels=1000
set confirm
set updatetime=1500

set encoding=utf-8
set termencoding=utf-8
set noerrorbells visualbell t_vb=

set hlsearch
set ignorecase
set smartcase

set background=dark
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
set laststatus=2
set number           " Show Line Numbers
" set relativenumber     " Show Relative Line Numbers
set numberwidth=4      " Width value of the Line Number Column
set ruler
set showmatch          " Shows matching brackets when text indicator is over them
set scrolloff=5        " Show 5 lines of context around the cursor
set cursorline

set showcmd
set ttyfast            " Improves redrawing for newer computers

	"Buffer Configuration {{{
	" Specify the behaviour when switching between buffers
	nnoremap <silent> <Left>   :bn<CR>
	nnoremap <silent> <Right>  :bp<CR>
	try
		set switchbuf=usetab
		set stal=2
	catch
	endtry

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

	" }}}

	nnoremap <leader>nw :%s/\s\+$//e<cr>:let @/=''<CR>
	nnoremap <leader>cssort ?{<CR>jV/^\s*\}?$<CR>k:sort<CR>:noh<CR>
	map <C-A> ggVG
highlight BadWhitespace ctermbg=red guibg=red
au BufRead,BufNewFile *.py,*.pyw match BadWhitespace /^\t\+/
au BufRead,BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/

au BufRead,BufNewFile *.py,*.pyw set tags+=$HOME/.vim/tags/python.ctags
au BufNewFile *.py,*.pyw,*.c,*.h set fileformat=unix

autocmd FileType python set omnifunc=pythoncomplete

set backspace=indent,eol,start

let python_highlight_all=1
syntax on

" set foldmethod=indent
autocmd BufWritePost *.py call Flake8()
execute pathogen#infect()

filetype indent on
filetype on
filetype plugin indent on

map <F2> :NERDTreeToggle<CR>

	let g:NERDTreeChristmasTree = 1
	let g:NERDTreeCaseSensitiveSort = 1
	let g:NERDTreeQuitOnOpen = 1
	let g:NERDTreeWinPos = 'left'
	let g:NERDTreeWinSize = 50
	let g:NERDTreeShowBookmarks = 1
