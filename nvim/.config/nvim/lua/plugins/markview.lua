return {
    "OXY2DEV/markview.nvim",
    lazy = false,
    opts = {
        preview = {
            icon_provider = "devicons", -- "internal", "mini" or "devicons"
        }
    },
    config = function(_, opts)
        require("markview").setup(opts);
        require("markview.extras.checkboxes").setup();
    end,
    dependencies = {
        "saghen/blink.cmp",
    },
};
