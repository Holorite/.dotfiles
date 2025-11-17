return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    config = function()
        require('nvim-treesitter.configs').setup({
            ensure_installed = { "c", "cpp", "lua", "vim", "vimdoc", "python" , "typescript", "tsx", "javascript", "html", "css", "markdown", "markdown_inline", "bash" },
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
            },
        })
    end,
    build = function()
        require("nvim-treesitter.install").update({ with_sync = true })()
    end,
}
