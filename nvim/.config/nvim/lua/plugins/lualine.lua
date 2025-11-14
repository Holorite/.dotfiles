return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
        theme = 'tokyonight',
        sections = {
            lualine_b = { 'branch', 'diagnostics' },
        },
    },
}
