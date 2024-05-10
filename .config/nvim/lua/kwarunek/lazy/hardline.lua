return {
    'ojroques/nvim-hardline',
    config = function()
        require('hardline').setup {
            bufferline = true,  -- disable bufferline
            bufferline_settings = {
                exclude_terminal = false,  -- don't show terminal buffers in bufferline
                show_index = false,        -- show buffer indexes (not the actual buffer numbers) in bufferline
            },

        }
    end
}
