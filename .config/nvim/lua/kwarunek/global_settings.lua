local o = vim.opt

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- match errorMsg /\s\+$/

o.guicursor = ""
o.termguicolors = true
o.nu = true
o.relativenumber = false
o.expandtab = true
o.smartindent = true
o.wrap = false
o.swapfile = false
o.backup = false
o.writebackup = false
o.undodir = os.getenv("HOME") .. "/tmp/editor/undodir"
o.undofile = false
o.hlsearch = true
o.scrolloff = 8
o.signcolumn = "yes"
o.isfname:append("@-@")
o.updatetime = 100
o.colorcolumn = "120"
o.autochdir = true
o.autoindent = true
o.smarttab = true
o.showmode = false
o.report = 0
o.history = 1000
o.undolevels = 1000
o.confirm = true
o.encoding = "utf-8"
o.ignorecase = true
o.errorbells = false
o.smartcase = true
o.ruler = true
o.cursorline = true
o.showmatch = true
o.backspace = [[indent,eol,start]]
o.hidden = true
o.shiftwidth = 4

-- set matchpairs+=<:>
-- set nowildmenu
-- set directory=$HOME/.vim/swapfiles,/var/tmp,/tmp,.
-- set termencoding=utf-8
-- set noerrorbells visualbell t_vb=
-- set background=dark
-- set laststatus=2
-- set ttimeout          " for key codes
-- set ttimeoutlen=10    " unnoticeable small value
