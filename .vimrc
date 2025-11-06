" Ativa numeração de linhas
set number

" CORES
"colorscheme slate
"colorscheme sorbet
"colorscheme zaibatsu
colorscheme habamax

"<LEADER>E
let mapleader = " "
nnoremap <leader>e :e .<CR>

" <leader>f → busca arquivos com ** (recursivo) e autocompletar
nnoremap <leader>f :e **/*

nnoremap <leader>wq :q<CR>

" Auto-fechamento simples
inoremap ( ()<Left>
inoremap { {}<Left>
inoremap [ []<Left>
inoremap " ""<Left>
inoremap ' ''<Left>
inoremap < <><Left>

" Numeração relativa (útil para saltos com :j)
"set relativenumber

" Destaca a linha atual
set cursorline

" Ativa syntax highlighting
syntax off

" Configura indentação inteligente
set smartindent
set autoindent

" Usa espaços em vez de tabs (4 espaços)
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4

" Busca incremental e destaque
set incsearch
set hlsearch
set ignorecase
set smartcase

" Mostra comandos parciais
set showcmd

" Ativa mouse (útil em terminais)
set mouse=a

" Sempre mostra a barra de status
set laststatus=2

" Codificação UTF-8
set encoding=utf-8

" Desativa swap files (opcional, use com cuidado)
" set noswapfile
" set nobackup
" set undodir=~/.vim/undodir
" set undofile
