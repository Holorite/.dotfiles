local vault = vim.env.WORK_VAULT_DIR

return {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    cond = function()
        return vault and vault ~= "" and vim.fn.isdirectory(vault) == 1
    end,
    event = vault and {
        "BufReadPre " .. vault .. "/**.md",
        "BufNewFile " .. vault .. "/**.md",
    } or {},
    cmd = { "Obsidian" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
        workspaces = { { name = "work-vault", path = vault or "" } },
        frontmatter = { enabled = false },
        legacy_commands = false,
        ui = { enable = false },
        completion = { min_chars = 2 },
        templates = { folder = "templates" },
        note_id_func = function(title)
            if not title or title == "" then return tostring(os.time()) end
            return title:lower():gsub("%s+", "-"):gsub("[^%w%-]", "")
        end,
    },
    keys = {
        { "<leader>oo", function() Snacks.picker.files({ focus = "input", cwd = vault, exclude = { "templates", ".obsidian" } }) end, desc = "Vault: quick switch" },
        { "<leader>os", function() Snacks.picker.grep({ focus = "input", cwd = vault }) end, desc = "Vault: search" },
        { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Vault: backlinks" },
        { "<leader>of", "<cmd>Obsidian follow_link<cr>", desc = "Vault: follow link" },
        { "<leader>on", "<cmd>Obsidian new<cr>", desc = "Vault: new note" },
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
                vim.fn.system({ "vault", "delete", file })
                vim.cmd("bdelete!")
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
