return {
    "gisketch/triforce.nvim",
    lazy = false,
    dependencies = {
        "nvzone/volt",
    },
    opts = {
        gamification_enabled = true,
    },
    keys = {
        { "<leader>tp", mode = "n", function() require('triforce').show_profile() end, desc = "Show Triforce Profile" }
    }
}
