return {
    "ovk/endec.nvim",
    event = "VeryLazy",
    config = function ()
        require('endec').setup({
            keymaps = {
                defaults = false,
                decode_base64_inplace = "gyb",
                vdecode_base64_inplace = "gyb",
                encode_base64_inplace = "gB",
                vencode_base64_inplace = "gB",
            }
        })
    end
}
