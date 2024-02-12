--TODO migrate to lua
--
vim.cmd([[
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

let mapleader = ","

nnoremap <F3> :set invpaste paste?<CR>

set pastetoggle=<F3>
nnoremap <leader>nw :%s/\s\+$//e<cr>:let @/=''<CR>
nnoremap <leader>w :%s/\s\+$//<cr>:let @/=''<CR>

" CTRL+A - select all
map <C-A> ggVG

map <F1> :set invcursorcolumn<CR>:IndentLinesToggle<CR>
map <F2> :NvimTreeToggle<CR>
map <F4> gcc

nnoremap <silent> <Left>   :bn<CR>
nnoremap <silent> <Right>  :bp<CR>

]])

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true


local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    {
        "rebelot/kanagawa.nvim",
        lazy = false,
        priority = 1000,
        opts = {}
    },
    'tpope/vim-fugitive',
    'crusj/structrue-go.nvim',
    'nvim-tree/nvim-web-devicons',
    {
        'numToStr/Comment.nvim',
        opts = {},
        lazy = false,
    },
    {
        "nvim-tree/nvim-tree.lua",
        version = "*",
        lazy = false
    },
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' }
    },
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function ()
            local configs = require("nvim-treesitter.configs")

            configs.setup({
                ensure_installed = { "asm", "awk", "bash", "c", "capnp", "cmake", "cpp", "css", "csv", "d", "diff", "dockerfile", "doxygen", "gdscript", "go", "gosum", "gomod", "groovy", "hcl", "html", "ini", "java", "json", "jsdoc", "lua", "make", "markdown", "objdump", "pascal", "perl", "php", "puppet", "python", "rego", "rst", "ruby", "rust", "sql", "strace", "templ", "terraform", "toml", "typescript", "vim", "vimdoc", "xml", "yaml", "zig"},
                sync_install = false,
                highlight = { enable = true },
                indent = { enable = true },
            })
        end
    },
    {'romgrk/barbar.nvim',
        dependencies = {
            'nvim-tree/nvim-web-devicons', 
        },
        init = function() vim.g.barbar_auto_setup = false end,
        opts = {
            highlight_visible = true,
            color_icons = true
        }
    }
})


require("nvim-tree").setup({
    actions = {
        open_file = {
            quit_on_open = true,
        },
    },
    renderer = {
        icons = {
            show = {
                git = false,
                modified = false,
                diagnostics = false,
                bookmarks = false
            }
        }
    }
})

require('lualine').setup {
    options = {
        theme = 'kanagawa',
    },
}
require("structrue-go").setup({
    show_filename = false, -- bool
    number = "no", -- show number: no | nu | rnu
})

require('kanagawa').setup({
    compile = false,             -- enable compiling the colorscheme
    undercurl = true,            -- enable undercurls
    commentStyle = { italic = false },
    functionStyle = {},
    keywordStyle = { italic = false},
    statementStyle = { bold = true },
    typeStyle = {},
    transparent = false,         -- do not set background color
    dimInactive = false,         -- dim inactive window `:h hl-NormalNC`
    terminalColors = true,       -- define vim.g.terminal_color_{0,17}
    colors = {                   -- add/modify theme and palette colors
        palette = {},
        theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
    },
    overrides = function(colors) -- add/modify highlights
        return {}
    end,
    theme = "wave",              -- Load "wave" theme when 'background' option is not set
    background = {               -- map the value of 'background' option to a theme
        dark = "wave",           -- try "dragon" !
        light = "lotus"
    },
})


local ok, _ = pcall(vim.cmd, 'colorscheme kanagawa')
if not ok then
    vim.cmd 'colorscheme default'
end
