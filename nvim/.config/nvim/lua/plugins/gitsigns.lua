return {
    "lewis6991/gitsigns.nvim",
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
        signcolumn = true,
    },
    keys = {
        {
            "<leader>gtb",
            function() require("gitsigns").toggle_current_line_blame() end,
            desc = "Toggle inline git blame",
        },
        {
            "<leader>gb",
            function() require("gitsigns").blame() end,
            desc = "Open side bar with git blame",
        },
        {
            "<leader>gd",
            function() require("gitsigns").diffthis() end,
            desc = "Diff current file",
        }
    },
}
