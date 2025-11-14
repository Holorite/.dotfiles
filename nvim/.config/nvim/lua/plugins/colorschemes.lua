Scheme = 'catppuccin'

return {
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            styles = {
                comments = { italic = false },
                keywords = { italic = false }
            },
        },
        config = function(_, opts)
            require("tokyonight").setup(opts)
            if Scheme:find('tokyonight') then
                vim.cmd([[colorscheme tokyonight-night]])
            end
        end,
    },
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        opts = {
            auto_integrations = true,
        },
        config = function(_, opts)
            require("catppuccin").setup(opts)
            if Scheme:find('catppuccin') then
                vim.cmd([[colorscheme catppuccin-mocha]])
            end
        end,
    },
}
