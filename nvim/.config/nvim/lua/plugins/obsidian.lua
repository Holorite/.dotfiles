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
        { "<leader>oo", "<cmd>Obsidian quick_switch<cr>", desc = "Vault: quick switch" },
        { "<leader>os", "<cmd>Obsidian search<cr>", desc = "Vault: search" },
        { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Vault: backlinks" },
        { "<leader>of", "<cmd>Obsidian follow_link<cr>", desc = "Vault: follow link" },
        { "<leader>on", "<cmd>Obsidian new<cr>", desc = "Vault: new note" },
    },
}
