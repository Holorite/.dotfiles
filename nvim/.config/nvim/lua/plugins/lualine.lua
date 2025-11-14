return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    -- TODO: Remove the time module
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
                    lualine_y = {
                        { "progress", separator = " ", padding = { left = 1, right = 0 } },
                        { "location", padding = { left = 0, right = 1 } },
                    },
                    lualine_z = {
                        {
                            function()
                                return " " .. os.date("%R")
                            end,
                            separator = { right = "" },
                        },
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
