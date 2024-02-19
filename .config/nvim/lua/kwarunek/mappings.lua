vim.g.mapleader = ','
vim.g.pastetoggle = '<F3>'
vim.api.nvim_set_keymap('n', '<F3>', ':set invpaste paste?<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-A>', 'ggVG', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F1>', ':set invcursorcolumn<CR>:IndentLinesToggle<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F2>', '<Esc>:NvimTreeToggle<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<F2>', '<Esc>:NvimTreeToggle<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Left>', ':bn<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Right>', ':bp<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>nw', ':%s/\\s\\+$//e<cr>:let @/=\'\'<cr>', { noremap = true, silent = true })
