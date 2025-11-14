vim.g.mapleader = "<Space>"
vim.opt.termguicolors=true

require('config.lazy')

vim.lsp.config('clangd', { cmd = { 'clangd' }, root_markers = { "compile_commands.json", ".git" } })

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

vim.opt.wrap=false

-- highlight searches
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

local function map(mode, shortcut, command, desc)
    vim.keymap.set(mode, shortcut, command, { noremap = true, silent = false, desc = desc }) -- change silent to true if you want idk
end

local function nmap(shortcut, command, desc)
    map('n', shortcut, command, desc)
end
local function vmap(shortcut, command, desc)
    map('n', shortcut, command, desc)
end
local function imap(shortcut, command, desc)
    map('i', shortcut, command, desc)
end
local function tmap(shortcut, command, desc)
    map('t', shortcut, command, desc)
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
nmap("<leader>n", ":noh<CR>")
tmap("<Esc>", "<C-\\><C-n>")

-- Recenter convenience
nmap('<C-u>', '<C-u>zz')
nmap('<C-d>', '<C-d>zz')
nmap('n', 'nzz')
nmap('N', 'Nzz')
nmap('[m', '[mzz')
nmap(']m', ']mzz')

vim.diagnostic.config({signs = false})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local bufmap = function(mode, lhs, rhs, description)
      local opts = {buffer = ev.buffer, desc=description}
      vim.keymap.set(mode, lhs, rhs, opts)
    end

    bufmap("n", "K", function() vim.lsp.buf.hover() end, 'Open hover')
    bufmap("n", "<leader>vca", function() vim.lsp.buf.code_action() end, 'Code actions')
    bufmap("n", "<leader>vrn", function() vim.lsp.buf.rename() end, 'Rename')
    bufmap("n", "[d", function() vim.diagnostic.goto_prev() end, 'Go to prev diagnostic')
    bufmap("n", "]d", function() vim.diagnostic.goto_next() end, 'Go to next diagnostic')
  end
})

