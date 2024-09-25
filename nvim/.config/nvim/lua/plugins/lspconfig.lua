return { 
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function() 
        require("lspconfig").clangd.setup{}
        require("lspconfig").pyright.setup{}
    end,
}
