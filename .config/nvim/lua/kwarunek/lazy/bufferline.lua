return {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    version = "*",
    opts = {
        options = {
            mode = "buffers",
            style_preset = "minimal",
            show_close_icon = false,
            show_buffer_icons = false,
            show_buffer_close_icons = false,
            middle_mouse_command = nil,
            right_mouse_command = nil,
            left_mouse_command = nil,
            color_icons = false,
            separator_style = "thin",
            hover = { enabled = false }
        },
    },
}
