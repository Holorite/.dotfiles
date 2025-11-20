return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = function()
        local colo = vim.g.colors_name
        if colo:find("catppuccin") then
            return {
                options = {
                    component_separators = "",
                    section_separators = { left = "", right = "" },
                },
                winbar = {
                    -- first component here is just so that the newline is always there
                    lualine_c = { { function() return ' ' end, padding = { left = 0, right = 0 }, color = { bg = "NONE" } }, 'navic' },
                },
                sections = {
                    lualine_a = { { "mode", separator = { left = "" }, right_padding = 2 } },
                    lualine_b = { 'branch', 'diagnostics' },
                    lualine_c = { { 'filename', path = 1 } },
                    lualine_x = { 'diff' },
                    lualine_y = {
                        'lsp_status',
                        'filetype',
                    },
                    lualine_z = {
                        { "progress", separator = " ", padding = { left = 1, right = 0 } },
                        { "location", padding = { left = 0, right = 0 }, separator = { right = "" } },
                    },
                },
            }
        end

        return {
            winbar = {
                lualine_c = { { function() return ' ' end, padding = { left = 0, right = 0 }, color = { bg = "NONE" } }, 'navic' },
            },
            sections = {
                lualine_b = { 'branch', 'diagnostics' },
            },
        }
    end,
}
