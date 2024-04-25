return {
    "laytan/cloak.nvim",
    config = function() 
        require("cloak").setup({
            enabled = true,
            cloak_character = "*",
            patterns = {
                {
                    file_pattern = {
                        ".env*",
                        "credentials",
                    },
                    cloak_pattern = "=.+"
                },
                {
                    file_pattern = {
                        "id_rsa*",
                        "id_ed*",
                        "*.pem"
                    },
                    cloak_pattern = ".*"
                },
            },
        })
    end
}
