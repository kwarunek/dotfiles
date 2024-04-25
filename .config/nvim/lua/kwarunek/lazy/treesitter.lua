return    {
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
}
