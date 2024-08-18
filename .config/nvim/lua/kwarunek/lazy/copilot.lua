return {
    "zbirenbaum/copilot.lua",
    version = "*",
    lazy = false,
    event = "InsertEnter",
    config = function()
        require("copilot").setup({})
    end,
}
