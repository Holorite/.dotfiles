local dashboard_config = {
    enabled = true,
    sections = {
        { section = "header" },
        {
            pane = 2,
            section = "terminal",
            cmd = "colorscript -e square",
            height = 5,
            padding = 1,
        },
        { section = "keys", gap = 1, padding = 1 },
        { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
        { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
        {
            pane = 2,
            icon = " ",
            title = "Git Status",
            section = "terminal",
            enabled = function()
                return Snacks.git.get_root() ~= nil
            end,
            cmd = "git status --short --branch --renames",
            height = 5,
            padding = 1,
            ttl = 5 * 60,
            indent = 3,
        },
        { section = "startup" },
    },
}

return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
        -- bigfile = { enabled = true },
        dashboard = dashboard_config,
        -- explorer = { enabled = true },
        indent = {
            enabled = true,
            only_scope = true,
            animate = {
                enabled = false,
            },
            scope = {
                hl= "FoldColumn",
            },
        },
        -- input = { enabled = true },
        -- picker = { enabled = true },
        -- notifier = { enabled = true },
        -- quickfile = { enabled = true },
        scope = { enabled = true },
        -- scroll = { enabled = true, },
        -- statuscolumn = { enabled = true },
        -- words = { enabled = true },
    },
}
