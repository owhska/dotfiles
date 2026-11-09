"curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
"https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

let mapleader = " "
let maplocalleader = "\\"

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
set clipboard=unnamedplus

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

"nnoremap <silent> <leader>e :Explore<CR>
nnoremap <silent> <C-e>e :Explore<CR>
nnoremap <silent> <leader><Tab>   :tabnext<CR>
nnoremap <silent> <leader><S-Tab> :tabprevious<CR>
nnoremap <silent> <leader>t :term<CR>
nnoremap <silent> <C-p> :tabe \| :Ex<CR>
nnoremap <silent> <leader>ww :w<CR>
nnoremap <leader>f :e<Space>
nnoremap <leader>wq :q<CR>
nnoremap <leader>ww :w<CR>
nnoremap <leader>q :tabclose<CR>
nnoremap <C-a> gg<S-v>G
nnoremap <leader>s :execute "vimgrep /" . input("Search: ") . "/g %" \| copen<CR>
nnoremap <C-b> :b <C-d>
nnoremap <S-Right> :bnext<CR>
nnoremap <S-Left>  :bprevious<CR>

tnoremap <C-w>h <C-\><C-n><C-w>h
tnoremap <C-w>l <C-\><C-n><C-w>l

inoremap ( ()<Left>
inoremap { {}<Left>
inoremap [ []<Left>
inoremap " ""<Left>
inoremap ' ''<Left>
inoremap < <><Left>


nnoremap <leader>wv :vsplit<CR>
nnoremap <leader>ws :split<CR>
nnoremap <leader>wh <C-w>h
nnoremap <leader>wl <C-w>l
nnoremap <leader>wj <C-w>j
nnoremap <leader>wk <C-w>k

nnoremap <S-h> ^
onoremap <S-h> ^
xnoremap <S-h> ^
nnoremap <S-l> g_
onoremap <S-l> g_
xnoremap <S-l> g_

vnoremap <silent> K :m '<-2<CR>gv=gv
vnoremap <silent> J :m '>+1<CR>gv=gv

inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

nnoremap <leader>rr :%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>

nnoremap <leader><left>  :vertical resize +20<CR>
nnoremap <leader><right> :vertical resize -20<CR>
nnoremap <leader><up>    :resize +10<CR>
nnoremap <leader><down>  :resize -10<CR>

nnoremap <leader>ll :set list!<CR>

vnoremap <C-c> "+y
vnoremap <leader>y "+y
nnoremap <leader>y "+y
nnoremap <leader>p "+p
nnoremap <leader>P "+P

nnoremap dd "_dd
vnoremap d "_d

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
