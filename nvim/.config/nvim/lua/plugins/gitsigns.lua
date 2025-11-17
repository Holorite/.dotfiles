return {
    "lewis6991/gitsigns.nvim",
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
        signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
        numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
        linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
        word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
    },
    keys = {
        {
            "<leader>gtb",
            function() require("gitsigns").toggle_current_line_blame() end,
            desc = "Toggle inline git blame",
        },
        {
            "<leader>gB",
            function() require("gitsigns").blame() end,
            desc = "Open side bar with git blame",
        },
        {
            "<leader>gd",
            function() require("gitsigns").diffthis() end,
            desc = "Diff current file",
        },
        {
            "]c",
            function()
                if vim.wo.diff then
                    vim.cmd.normal({']c', bang = true})
                else
                    require("gitsigns").nav_hunk('next')
                end
            end,
            desc = "Go to next hunk",
        },
        {
            "[c",
            function()
                if vim.wo.diff then
                    vim.cmd.normal({'[c', bang = true})
                else
                    require("gitsigns").nav_hunk('prev')
                end
            end,
            desc = "Go to prev hunk",
        },
        {
            "ih",
            function()
                require("gitsigns").select_hunk()
            end,
            mode = {'o', 'x'},
            desc = 'Select hunk',
        },
        {
            "<leader>hs",
            function() require("gitsigns").stage_hunk() end,
            desc = 'Stage hunk',
        },
        {
            "<leader>hr",
            function() require("gitsigns").reset_hunk() end,
            desc = 'Reset hunk',
        }
    },
}
