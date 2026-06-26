return {
    'serhez/bento.nvim',
    lazy = true,
    init = function()
        local function try_load_bento()
            if #vim.fn.getbufinfo({ buflisted = 1 }) > 1 then
                require("bento")
                return true
            end
        end
        vim.api.nvim_create_autocmd("BufAdd", { callback = try_load_bento })
        vim.api.nvim_create_autocmd("VimEnter", { callback = try_load_bento })
    end,
    opts = {
        max_open_buffers = 8,
        buffer_deletion_metric = "frecency_access",
        buffer_notify_on_delete = true,
        ui = {
            floating = {
                minimal_menu = 'dashed',
            },
        },
    }
}
