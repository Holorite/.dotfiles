return {
    'serhez/bento.nvim',
    lazy = true,
    init = function()
        vim.api.nvim_create_autocmd("BufAdd", {
            callback = function()
                if #vim.fn.getbufinfo({ buflisted = 1 }) > 1 then
                    require("bento")
                    return true
                end
            end,
        })
    end,
    opts = {
        max_open_buffers = 6,
        buffer_deletion_metric = "frecency_access",
        buffer_notify_on_delete = true,
        ui = {
            floating = {
                minimal_menu = 'dashed',
            },
        },
    }
}
