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
    cmd = { "ObsidianQuickSwitch", "ObsidianSearch", "ObsidianBacklinks", "ObsidianNew", "ObsidianFollowLink" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
        workspaces = { { name = "work-vault", path = vault or "" } },
        disable_frontmatter = true,
        ui = { enable = false },
        completion = { nvim_cmp = false, blink = true, min_chars = 2 },
        templates = { folder = "templates" },
        note_id_func = function(title)
            if not title or title == "" then return tostring(os.time()) end
            return title:lower():gsub("%s+", "-"):gsub("[^%w%-]", "")
        end,
    },
    keys = {
        { "<leader>oo", "<cmd>ObsidianQuickSwitch<cr>", desc = "Vault: quick switch" },
        { "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Vault: search" },
        { "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Vault: backlinks" },
        { "<leader>of", "<cmd>ObsidianFollowLink<cr>", desc = "Vault: follow link" },
        { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "Vault: new note" },
    },
}
