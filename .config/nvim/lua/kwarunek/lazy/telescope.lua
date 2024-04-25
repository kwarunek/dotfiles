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

        vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
        vim.keymap.set('n', '<leader>pws', function()
            local word = vim.fn.expand("<cword>")
            builtin.grep_string({ search = word })
        end)
        vim.keymap.set('n', '<leader>pWs', function()
            local word = vim.fn.expand("<cWORD>")
            builtin.grep_string({ search = word })
        end)
        vim.keymap.set('n', '<C-p>', builtin.git_files, {})
    end
}
