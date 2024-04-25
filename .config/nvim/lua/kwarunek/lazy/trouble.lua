return {
    {
        "folke/trouble.nvim",
        config = function()
            require("trouble").setup({
                icons = false,
            })
            vim.keymap.set("n", "<F4>", function()
                require("trouble").toggle()
            end)
        end
    },
}
