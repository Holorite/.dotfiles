vim.g.mapleader = "<Space>"
vim.opt.termguicolors=true
-- vim.lsp.set_log_level('debug')

require('config.lazy')

vim.lsp.config('clangd', { cmd = { 'clangd' }, root_markers = { "compile_commands.json", ".git" } })
-- vim.lsp.config('clangd', { cmd = { 'clangd', '--query-driver=/usr/bin/clang*' }, root_markers = { "compile_commands.json", ".git" } })
-- vim.lsp.config('clangd', { cmd = { '/prj/qct/mlsys/markham/scratch/juliray/hexagon-nn-v3/run-in-docker clangd', '--query-driver=/usr/bin/clang' }, root_markers = { "compile_commands.json", ".git" } })
-- vim.lsp.config('clangd', { cmd = { 'clangd', '--log=verbose', '-j=1' }, root_markers = { "compile_commands.json", ".git" } })

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

vmap('<Space>', '<Nop>')

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

local tc = require('telescope.builtin')

nmap("<leader>ff", function() tc.git_files() end, "Telescope find git files")
nmap("<leader>fa", function() tc.find_files() end, "Telescope find")
vmap("<leader>fs", function() tc.grep_string() end, "Telescope grep cursor string")
nmap("<leader>fg", function() tc.live_grep() end, "Telescope live grep")
nmap("<leader>fz", function() tc.current_buffer_fuzzy_find() end, 'Fuzzy find in current file')
nmap("<leader>fo", function() tc.live_grep({grep_open_files=true}) end, 'Telescope grep in open files')
nmap("<leader>fh", function() tc.help_tags() end, "Telescope help tags")
nmap("<leader>fb", function() tc.buffers() end, "Telescope buffers")

vim.api.nvim_set_keymap(
  "n",
  "<leader>fB",
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

    bufmap("n", "gd", function() vim.lsp.buf.definition() end, 'Go to definition')
    bufmap("n", "gt", "<cmd>tab split | lua vim.lsp.buf.definition()<CR>", "Go to definition in new tab")

    bufmap("n", "K", function() vim.lsp.buf.hover() end, 'Open hover')
    bufmap("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, 'Workspace symbol')
    bufmap("n", "<leader>vca", function() vim.lsp.buf.code_action() end, 'Code actions')
    bufmap("n", "<leader>vrr", function() vim.lsp.buf.references() end, 'References')
    bufmap("n", "<leader>vrn", function() vim.lsp.buf.rename() end, 'Rename')
    bufmap('n', '<C-j>', function() vim.diagnostic.open_float() end, 'Open float')
    bufmap("n", "[d", function() vim.diagnostic.goto_prev() end, 'Go to prev diagnostic')
    bufmap("n", "]d", function() vim.diagnostic.goto_next() end, 'Go to next diagnostic')
  end
})

