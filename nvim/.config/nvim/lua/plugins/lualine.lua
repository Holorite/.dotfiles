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
                sections = {
                    lualine_a = { { "mode", separator = { left = "" }, right_padding = 2 } },
                    lualine_b = { 'branch', 'diagnostics' },
                    lualine_c = { 'filename' },
                    lualine_x = { 'diff' },
                    lualine_y = { 'filetype' },
                    lualine_z = {
                        { "progress", separator = " ", padding = { left = 1, right = 0 } },
                        { "location", padding = { left = 0, right = 0 }, separator = { right = "" } },
                    },
                },
            }
        end

        return {
            sections = {
                lualine_b = { 'branch', 'diagnostics' },
            },
        }
    end,
}
