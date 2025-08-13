vim.g.mapleader = "<Space>"

require('config.lazy')

vim.opt.background = "dark"

-- num settings
vim.opt.relativenumber=true
vim.opt.nu=true

-- DONT EVER REMOVE
vim.opt.errorbells=false

-- keep closed files in buffer (dont need to save to exit and browse)
vim.opt.hidden=true

-- tabs
vim.opt.tabstop=4 
vim.opt.softtabstop=4
vim.opt.shiftwidth=4
vim.opt.expandtab=true
vim.opt.smartindent=true

vim.opt.wrap=false

-- highlight searches
vim.opt.hlsearch=false
vim.opt.hlsearch=true
vim.opt.incsearch=true
vim.opt.ignorecase=true

-- starts scrolling file from +/- 8 lines from top/bottom
vim.opt.scrolloff=8


vim.opt.updatetime=80

vim.opt.signcolumn="yes"

vim.opt.showcmd=true             -- Show (partial) command in status line.
vim.opt.showmatch=true           -- Show matching brackets.
vim.opt.autowrite=true           -- Automatically save before commands like :next and :make

vim.opt.showtabline=2

vim.opt.splitbelow=true
vim.opt.splitright=true

vim.opt.mouse=""

vim.g.matchparen_timeout = 2
vim.g.matchparen_insert_timeout = 2

-- tabline settings at the top of the screen
function Tabline()
    local line = ''
    local current = vim.fn.tabpagenr()

    for i = 1, vim.fn.tabpagenr('$') do
        if i == current then
            line = line .. '%#TabLineSel#'
        else
            line = line .. '%#TabLine#'
        end

        local label = vim.fn.fnamemodify(vim.fn.bufname(vim.fn.tabpagebuflist(i)[vim.fn.tabpagewinnr(i)]), ':t')

        line = line .. '%' .. i .. 'T' -- Starts mouse click target region.
        line = line .. '  ' .. label .. '  '
    end

    line = line .. '%#TabLineFill#'
    line = line .. '%T' -- Ends mouse click target region(s).

    return line
end

vim.opt.tabline = "%!v:lua.Tabline()"

function map(mode, shortcut, command)
    vim.api.nvim_set_keymap(mode, shortcut, command, { noremap = true, silent = false }) -- change silent to true if you want idk
end

function nmap(shortcut, command)
    map('n', shortcut, command)
end

function imap(shortcut, command)
    map('i', shortcut, command)
end

function tmap(shortcut, command)
    map('t', shortcut, command)
end

nmap("vs", ":vs<CR>")
nmap("sp", ":sp<CR>")
nmap("<C-L>", "<C-W><C-L>")
nmap("<C-H>", "<C-W><C-H>")
nmap("<C-K>", "<C-W><C-K>")
nmap("<C-J>", "<C-W><C-J>")
nmap("tn", ":tabnew<CR>")
nmap("tk", ":tabnext<CR>")
nmap("tj", ":tabprev<CR>")
nmap("to", ":tabo<CR>")
nmap("<C-S>", ":%s/")
nmap("<C-N>", ":Lexplore<CR> :vertical resize 30<CR>")
nmap("<leader>n", ":noh<CR>")
tmap("<Esc>", "<C-\\><C-n>")

nmap("<leader>ff", "<cmd>Telescope find_files<cr>")
nmap("<leader>fg", "<cmd>Telescope live_grep<cr>")
nmap("<leader>fb", "<cmd>Telescope buffers<cr>")
nmap("<leader>fh", "<cmd>Telescope help_tags<cr>")

vim.api.nvim_set_keymap(
  "n",
  "<leader>fb",
  ":Telescope file_browser<CR>",
  { noremap = true }
)

-- open file_browser with the path of the current buffer
vim.api.nvim_set_keymap(
  "n",
  "<leader>fc",
  ":Telescope file_browser path=%:p:h select_buffer=true<CR>",
  { noremap = true }
)

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local bufmap = function(mode, lhs, rhs)
      local opts = {buffer = true}
      vim.keymap.set(mode, lhs, rhs, opts)
    end

    -- Displays hover information about the symbol under the cursor
    bufmap('n', '<C-j>', '<cmd>lua vim.diagnostic.open_float()<cr>')
    bufmap('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>')
  end
})

