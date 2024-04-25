require("kwarunek.global_settings")
require("kwarunek.mappings")
require("kwarunek.lazy_setup")


local ok, _ = pcall(vim.cmd, 'colorscheme kanagawa')
if not ok then
    vim.cmd 'colorscheme default'
end


