"curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
"https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

set noerrorbells
set novisualbell
set t_vb=
set belloff=all
set shortmess+=cI
set t_te=

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
let g:netrw_banner=0
let g:netrw_liststyle=3
let g:netrw_browse_split=0

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

nnoremap <silent> <leader>e :Explore<CR>
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
nnoremap <C-e> :b <C-d>
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

set completeopt=menuone,noinsert,noselect

function! DispararOmniAutomatico()
    if pumvisible() || v:char !~ '\w'
        return
    endif
    if &omnifunc !=# ''
        call feedkeys("\<C-x>\<C-o>", 'n')
    else
        call feedkeys("\<C-x>\<C-n>", 'n')
    endif
endfunction

augroup OmniAuto
    autocmd!
    autocmd FileType javascript,python,c,cpp,html,css,vim
                \ autocmd InsertCharPre <buffer> call DispararOmniAutomatico()
augroup END

function! s:ToggleComment() abort
    let l:cs = &commentstring
    let l:prefix = matchstr(l:cs, '^.\{-}\ze\s*%s')

    if empty(l:prefix)
        echohl WarningMsg | echom "Invalid commentstring: " . l:cs | echohl None
        return
    endif

    let l:start_line = line("'<")
    let l:end_line   = line("'>")
    if l:start_line > l:end_line
        let [l:start_line, l:end_line] = [l:end_line, l:start_line]
    endif

    let l:all_commented = 1
    let l:prefix_esc = escape(l:prefix, '\.*$^~[]')
    for i in range(l:start_line, l:end_line)
        let l = getline(i)
        if l !~# '^\s*' . l:prefix_esc
            let l:all_commented = 0
            break
        endif
    endfor

    for i in range(l:start_line, l:end_line)
        let l = getline(i)
        if l:all_commented
            let l:new = substitute(l, '^\s*\zs' . l:prefix_esc . '\s\?', '', '')
        else
            let l:indent = matchstr(l, '^\s*')
            let l:rest   = l[len(l:indent):]
            let l:new    = l:indent . l:prefix . ' ' . l:rest
        endif
        call setline(i, l:new)
    endfor

    execute "normal! \<Esc>"
endfunction

vnoremap <leader>cm :<C-u>call <SID>ToggleComment()<CR>

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
