lua << EOF
require('config.lazy')
EOF

set background=dark

set tabline=
" cursor block

" num settings
set relativenumber
set nu

" DONT EVER REMOVE
set noerrorbells

" keep closed files in buffer (dont need to save to exit and browse)
set hidden

" tabs
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent

set nowrap

" highlight searches
"set nohlsearch
set hlsearch
set incsearch
set ignorecase

" starts scrolling file from +/- 8 lines from top/bottom
set scrolloff=8


set signcolumn=no

set updatetime=80


set showcmd             " Show (partial) command in status line.
set showmatch           " Show matching brackets.
set autowrite           " Automatically save before commands like :next and :make

set showtabline=2

set splitbelow
set splitright

let g:matchparen_timeout = 2
let g:matchparen_insert_timeout = 2

" tabline settings at the top of the screen
function! Tabline() abort
    let l:line = ''
    let l:current = tabpagenr()

    for l:i in range(1, tabpagenr('$'))
        if l:i == l:current
            let l:line .= '%#TabLineSel#'
        else
            let l:line .= '%#TabLine#'
        endif

        let l:label = fnamemodify(
            \ bufname(tabpagebuflist(l:i)[tabpagewinnr(l:i) - 1]),
            \ ':t'
        \ )

        let l:line .= '%' . i . 'T' " Starts mouse click target region.
        let l:line .= '  ' . l:label . '  '
    endfor

    let l:line .= '%#TabLineFill#'
    let l:line .= '%T' " Ends mouse click target region(s).

    return l:line
endfunction

set tabline=%!Tabline()



let mapleader = "\<Space>"

let mapleader = "\<Space>"

nnoremap vs :vs<CR>
nnoremap sp :sp<CR>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-J> <C-W><C-J>
nnoremap tn :tabnew<CR>
nnoremap tk :tabnext<CR>
nnoremap tj :tabprev<CR>
nnoremap to :tabo<CR>
nnoremap <C-S> :%s/
nnoremap <C-N> :Lexplore<CR> :vertical resize 30<CR>
nnoremap <silent> <leader>t :sp<CR> :term<CR> :resize 20N<CR> i
nnoremap <leader>n :noh<CR>
tnoremap <Esc> <C-\><C-n>

nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

lua << EOF
vim.api.nvim_set_keymap(
  "n",
  "<space>fb",
  ":Telescope file_browser<CR>",
  { noremap = true }
)

-- open file_browser with the path of the current buffer
vim.api.nvim_set_keymap(
  "n",
  "<space>fc",
  ":Telescope file_browser path=%:p:h select_buffer=true<CR>",
  { noremap = true }
)
EOF

set mouse=
