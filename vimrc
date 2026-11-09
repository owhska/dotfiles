"curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
"https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

call plug#begin()
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

call plug#end()

" general
set nocompatible
set noerrorbells
set novisualbell
set backspace=indent,eol,start
set encoding=utf-8
set background=dark

" indentation
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4

" search
set incsearch
set hlsearch
set ignorecase
set smartcase

" interface
set showcmd
set ruler
"set number
set showmatch

" editing
set noswapfile
set hidden

" save and quit
nnoremap <space>w :w<cr>
nnoremap <space>wq :q<cr>
nnoremap <space>q :q!<cr>
nnoremap <C-p> :tabnew<Space>
nnoremap <Space>f :e<Space>
nnoremap <silent> <Space><Tab>   :tabnext<CR>
nnoremap <silent> <Space><S-Tab> :tabprevious<CR>

colorscheme default
set background=light            " Light background is best
hi Comment ctermfg=63		" Brighten up comment colors
hi Search ctermbg=LightYellow	" Search color

let g:airline_powerline_fonts = 0
let g:airline_theme = "deus"

let g:ale_completion_enabled = 0

" only run lint when file is saved
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_on_enter = 0

" configure preview window
let g:ale_floating_preview = 1
let g:ale_floating_window_border = ['│', '─', '╭', '╮', '╯', '╰', '│', '─']
let g:ale_hover_to_floating_preview = 1

" quiet down ale
let g:ale_virtualtext_cursor = 0

" Buffer completion
nnoremap <C-e> :b <C-d>

" navigation between buffers
nnoremap <s-right> :bnext<cr>
nnoremap <s-left> :bprevious<cr>

" splits
nnoremap <space>ws :split<cr>
nnoremap <space>wv :vsplit<cr>
nnoremap <space>wh <c-w>h
nnoremap <space>wl <c-w>l
nnoremap <space>wj <c-w>j
nnoremap <space>wk <c-w>k

" move selected lines
vnoremap j :m '>+1<cr>gv
vnoremap k :m '<-2<cr>gv

" select all
nnoremap <c-a> ggvg

" clear search highlighting
nnoremap <space>/ :nohlsearch<cr>

" clipboard-independent delete
nnoremap dd "_dd
vnoremap d "_d

