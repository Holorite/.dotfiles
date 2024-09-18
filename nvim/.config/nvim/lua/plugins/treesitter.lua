return {
    "nvim-treesitter/nvim-treesitter",
    opts = {
        -- A list of parser names, or "all" (the five listed parsers should always be installed)
        ensure_installed = { "c", "cpp", "lua", "vim", "vimdoc", "python" , "typescript", "tsx", "javascript", "html", "css" },
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
        },
    },
    build = function()
        require("nvim-treesitter.install").update({ with_sync = true })()
    end,
}
