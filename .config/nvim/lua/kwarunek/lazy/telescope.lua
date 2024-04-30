return {
    'nvim-telescope/telescope.nvim', tag = '0.1.6',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
        local actions = require("telescope.actions")
        local action_layout = require("telescope.actions.layout")
        require('telescope').setup({
            defaults = {
                mappings = {
                    n = {
                        ["<M-p>"] = action_layout.toggle_preview
                    },
                    i = {
                        ["<esc>"] = actions.close,
                        ["<M-p>"] = action_layout.toggle_preview
                    },
                },
                results_title = false,
                prompt_title = false,
                preview ={
                    hide_on_startup = true,
                },
            },
        })

        require('telescope').load_extension('fzf')
        local builtin = require('telescope.builtin')

        local keymap = vim.keymap -- for conciseness

        keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
        keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
        keymap.set('n', '<leader>pws', function()
            local word = vim.fn.expand("<cword>")
            builtin.grep_string({ search = word })
        end)
        keymap.set('n', '<leader>pWs', function()
            local word = vim.fn.expand("<cWORD>")
            builtin.grep_string({ search = word })
        end)
        keymap.set('n', '<C-p>', builtin.git_files, {})
    end
}
