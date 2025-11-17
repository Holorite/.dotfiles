return {
    "fnune/recall.nvim",
    event = { 'BufReadPre', 'BufNewFile' },
    version = "*",
    opts = {
        sign_highlight = "@function", -- this is so that the background is not on by default like for @comment.note (this is the default)
    },
    keys = {
        { "<leader>mm", function() require("recall").toggle() end, desc = "Recall toggle" },
        { "<leader>mn", function() require("recall").goto_next() end, desc = "Recall next" },
        { "<leader>mp", function() require("recall").goto_prev() end, desc = "Recall previous" },
        { "<leader>mc", function() require("recall").clear() end, desc = "Recall clear" },
        { "<leader>ms", function() require("recall.snacks").pick({ focus = "list" }) end, desc = "Global Marks" },
    }
}
