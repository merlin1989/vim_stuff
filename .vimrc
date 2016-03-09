"set background=dark
set shortmess+=I
execute pathogen#infect()
syntax on
filetype plugin indent on

" We don't want vi compatibility.
set nocompatible 

" How many lines of history to remember
set history=10000

" Set a large undo tree
set undolevels=10000

" Automatically detect file types.
filetype plugin on
filetype indent on

" Set to auto read when a file is changed from outside
set autoread

" Set title automatically
set title

" Set a more convinient map leader
let mapleader=','

" Don't make windows equal after a split
set noea

" Ignore case when searching
set ignorecase

" Highlight search things
set hlsearch

" Incremental search please
set incsearch

" We want magic for regular expressions
set magic

" We don't like noise on errors
set noerrorbells
set novisualbell
set t_vb=

" Switch to paste mode
"set pastetoggle=<F2>

" Don't move your fingers to arrow keys for history
cnoremap <C-k> <Up>
cnoremap <C-j> <Down>

" Clear highlighting after search
nmap <silent> ,, :nohlsearch<cr>

" Enable syntax colloring
syntax enable

" Auto indent
set ai
set ci

" Smart indent
set si

" Format the statusline
"set statusline=\ %F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l/%L:%c
