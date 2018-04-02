set runtimepath+=/usr/share/bashstyle-ng/vim/
syntax on
set background=dark
if has("autocmd")
    au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
    \| exe "normal! g'\"" | endif
endif
if has("autocmd")
    filetype plugin indent on
endif
set autoindent
set smartindent
set showcmd
set showmatch
set noignorecase
set smartcase
set incsearch
set hls
set number
set noautowriteall
set cursorline
hi CursorLine term=none cterm=underline ctermbg=none
set nocursorcolumn
set ruler
set rulerformat=%45(%t\ %y\ %c\ %l\/%L\ %p%%%)
set nobackup
set nostartofline
set linespace=0
set nowrap
set tw=0
set tabstop=8
set softtabstop=8
set expandtab
set noautochdir
set nofoldenable
set wildmenu
if filereadable("~/.vimrc.custom")
	source ~/.vimrc.custom
endif
