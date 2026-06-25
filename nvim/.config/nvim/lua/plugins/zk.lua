local vault = vim.env.ZK_NOTEBOOK_DIR

return {
    "zk-org/zk-nvim",
    cond = function()
        return vault and vault ~= ""
            and vim.fn.isdirectory(vault) == 1
            and vim.fn.has("nvim-0.11") == 1
    end,
    event = vault and {
        "BufReadPre " .. vault .. "/**.md",
        "BufNewFile " .. vault .. "/**.md",
    } or {},
    cmd = { "ZkNew", "ZkNotes", "ZkBacklinks", "ZkLinks", "ZkTags", "ZkIndex" },
    config = function()
        require("zk").setup({
            picker = "snacks_picker",
            lsp = {
                config = {
                    root_dir = function()
                        if vault and vault ~= "" then
                            return vim.fn.expand(vault)
                        end
                        return vim.fs.root(0, ".zk")
                    end,
                    auto_attach = { enabled = true, filetypes = { "markdown" } },
                },
            },
        })
    end,
    keys = {
        { "<leader>oo", function() Snacks.picker.files({ focus = "input", cwd = vault }) end, desc = "Vault: files" },
        {
            "<leader>op",
            function()
                local slug = vim.trim(vim.fn.system("vault slug"))
                require("zk.commands").get("ZkNotes")({ hrefs = { "projects/" .. slug }, sort = { "modified" } })
            end,
            desc = "Vault: project notes",
        },
        { "<leader>os", function() Snacks.picker.grep({ focus = "input", cwd = vault }) end, desc = "Vault: search" },
        { "<leader>ob", "<cmd>ZkBacklinks<cr>", desc = "Vault: backlinks" },
        { "<leader>ol", "<cmd>ZkLinks<cr>", desc = "Vault: outgoing links" },
        {
            "<leader>or",
            function()
                local file = vim.api.nvim_buf_get_name(0)
                if file == "" or not file:find(vault, 1, true) then
                    vim.notify("Not a vault note", vim.log.levels.WARN)
                    return
                end
                require("zk.commands").get("ZkNotes")({ related = { file }, sort = { "modified" } })
            end,
            desc = "Vault: related notes",
        },
        { "<leader>ot", "<cmd>ZkTags<cr>", desc = "Vault: tags" },
        {
            "<leader>od",
            function()
                local file = vim.api.nvim_buf_get_name(0)
                if file == "" or not file:find(vault, 1, true) then
                    vim.notify("Not a vault note", vim.log.levels.WARN)
                    return
                end
                local name = vim.fn.fnamemodify(file, ":t")
                if vim.fn.confirm("Delete " .. name .. "?", "&Yes\n&No", 2) ~= 1 then return end
                local ok, err = os.remove(file)
                if not ok then
                    vim.notify("Delete failed: " .. (err or "unknown"), vim.log.levels.ERROR)
                    return
                end
                vim.cmd("bdelete!")
                vim.fn.system({ "vault", "sync", "vault: delete " .. name })
            end,
            desc = "Vault: delete note",
        },
        {
            "<leader>oS",
            function()
                vim.fn.system({ "vault", "sync" })
                vim.notify("Vault synced", vim.log.levels.INFO)
            end,
            desc = "Vault: sync",
        },
    },
}
