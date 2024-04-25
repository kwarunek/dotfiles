return {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    config = function()
        require("nvim-tree").setup({
            actions = {
                open_file = {
                    quit_on_open = true,
                },
            },
            view = {
                width = 40
            },
            renderer = {
                group_empty = true,
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
    end
}
