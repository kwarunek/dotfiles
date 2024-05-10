return {
    "cappyzawa/trim.nvim",
    opts = {},
    config = function()
        require("trim").setup({
            highlight = true,
            trim_on_write = false,
        })
    end
}
