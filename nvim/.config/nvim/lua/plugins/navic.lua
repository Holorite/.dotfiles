return {
    "SmiteshP/nvim-navic",
    lazy = false,
    init = function()
        vim.g.navic_silence = true
    end,
    opts = function()
        local Snacks = require('snacks')
        Snacks.util.lsp.on({ method = "LspAttach" }, function(buffer, client)
            require("nvim-navic").attach(client, buffer)
        end)
        return {
            -- separator = " ",
            highlight = true,
            -- depth_limit = 5,
            lazy_update_context = false,
        }
    end,
}
