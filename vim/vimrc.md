# Vim configuration
Because I was a vimmer sometime ago, and I keep using it when I forget to change the appropiate environment variable.

# Environment
## Basics
```
set nocompatible  " Must be the first line
```

## Setup plugin support
For loading pathogen as a submodule, for git
```
runtime bundle/vim-pathogen/autoload/pathogen.vim
execute pathogen#infect()
```

# General
```
set background=dark " Assume dark background
set t_Co=256        " Enable 256 colors
syntax enable       " Enables syntax highlight
colorscheme jellybeans " Choose colorscheme
set mouse=a " Enable mouse on all modes
```

## Avoiding 'Hit ENTER to continue' messages
```
set shortmess+=filmnrxoOtT " Abbr. of messages
set cmdheight=2 " Space for messages
```

# User interface
```
set number        " Show line numbers
set cursorline    " Highlight current line
set showmode      " Display current mode
set showmatch     " Show matching brackets/parenthesis
set showcmd       " Show partial command in status line and characters/lines
                  " in visual mode
set wildmenu      " Show list instead of just completing
set wildmode=list:longest,full " Command <TAB> completion, list matches, then
                                " longest common part, then all.
set scrolljump=5  " Number of lines to scroll when cursor leaves screen
set scrolloff=4   " Minimum number of lines to keep above and below cursor
set gdefault      " The /g flag is on :s substitutions
set nobk          " Turn backup off, since most stuff is in git anyway...
set nowb          " Prevents automatic backup
set wildignore=*.o,*.obj,*.bak,*.exe,*.x " These files must be ignored by VIM
set history=200   " Sets how many lines of history VIM has to remember
```

## Textual search
```
set ignorecase    " Case-insensitive search
set smartcase     " With this option, a search is case-insensitive if
                  " you enter the search string in ALL lower case
set hlsearch      " Highlight search
set incsearch     " Incremental search
```

## Text formatting
```
set wrap linebreak nolist " do soft word wrap
set shiftwidth=4 " Adjust the number of columns shifted by commands < or >
```

### Space vs TAB
```
set expandtab " Use spaces instead of TABs
set tabstop=4 " Each TAB has four spaces
set softtabstop=4 " Let backspace delete indent

set encoding=utf8 " Set utf8 as standard encoding and en_US as the standard language
```

# Misc settings
```
" No noise from VIM! {
    set noerrorbells
    " Hides buffers instead of close them
    set hidden
" }
set shellslash
set autoread       " Set to auto read when a file is changed from the outside
set noswapfile
```

# Statusline
```
" Always display the statusline
set laststatus=2
" Set statusline {
    set statusline=%.20F       " Path to the file
    set statusline+=\ -\       " Separator
    set statusline+=FileType:  " Label
    set statusline+=%y         " Filetype of the file
    set statusline+=\ -\       " Separator
    set statusline+=Line:\ %-4l\ Column:\ %-4c\ Total:\ %-4L
" }
```

# Shortcut mappings
```
" Saving keystrokes for saving a file
nnoremap ; :
" Clear last search pattern by hitting return
nnoremap <CR> :noh<CR><CR>
```

# Abbreviations
```
" For those who, like me, always accidentally hit the CAPS LOCK key
cab W w | cab WQ wq | cab Wq wq | cab wQ wq | cab Q q
" Abbreviation for displaying filename
inoremap \fname <C-R>=expand("%:t:r")<CR>
inoremap \vct <C-R>=expand("Victor Santos")<CR>

" Remove espaços redundantes no fim das linhas
" fiz uma adição ao comando depois do <esc> mz
" cria uma marca para voltar ao ponto em que se está
" e 'z retorna a este ponto ao final do comando
map <F7> <esc>mz:%s/\s\+$//g<cr>`z
" Cursor will not move if you press 'i' to enter insert mode, and then
" press ESC to exit
"inoremap <Esc> <Esc>`^
```

# Autocommands
```
au BufNewFile,BufRead *.tex,*.sty,*.cls set filetype=tex " .tex, .sty and .cls files are always LaTeX files
" Automatic folding save (VERY useful!) {
    "au BufWinLeave * silent! mkview
    "au BufWinEnter * silent! loadview
```

# Moving between screen lines
To use in line wrapping; when you do soft line breaking, moving the cursor
up and down will jump from one physical line to another; to move between
displayed lines, you must press gj and gk, and this is really annoying!

Although one can do the simple mapping
```
imap <silent> <Down> <C-o>gj
imap <silent> <Up> <C-o>gk
nmap <silent> <Down> gj
nmap <silent> <Up> gk
```

this actually breaks VIM's omnicompletion. The function below was found in

<http://vim.wikia.com/wiki/Move_cursor_by_display_lines_when_wrapping>

to be a nice solution for this problem.
```
function! NoremapNormalCmd(key, preserve_omni, ...)
  let cmd = ''
  let icmd = ''
  for x in a:000
    let cmd .= x
    let icmd .= "<C-\\><C-O>" . x
  endfor
  execute ":nnoremap <silent> " . a:key . " " . cmd
  execute ":vnoremap <silent> " . a:key . " " . cmd
  if a:preserve_omni
    execute ":inoremap <silent> <expr> " . a:key . " pumvisible() ? \"" . a:key . "\" : \"" . icmd . "\""
  else
    execute ":inoremap <silent> " . a:key . " " . icmd
  endif
endfunction

" Cursor moves by screen lines
call NoremapNormalCmd("<Up>", 1, "gk")
call NoremapNormalCmd("<Down>", 1, "gj")
call NoremapNormalCmd("<Home>", 0, "g<Home>")
call NoremapNormalCmd("<End>", 0, "g<End>")

hi clear SpellBad
hi SpellBad ctermfg=black ctermbg=white
map <leader>a :call SyntaxAttr()<CR>
```

# INFO
```
" Guarda posição do cursor e histórico da linha de comando
set viminfo='10,\"30,:40,%,n~/.viminfo
au BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif
```

# MISC
```
" Mostra os espaços em branco inúteis no final da linha
au BufNewFile,BufRead * match Error '\s\+$'

"=============================================================================80
" Este trecho faz parte de um script criado por Srinath Avadhanula
" <srinath@fastmail.fm> para atualizar automaticamente a data de modificacao
" em um arquivo quando este for salvo. O script encontra-se disponivel em
" http://www.vim.org/scripts/script.php?script_id=259
"=============================================================================80
if !exists('g:timeStampLeader')
    let s:timeStampLeader = 'Last Change: '
else
    let s:timeStampLeader = g:timeStampLeader
endif

function! UpdateWithLastMod()
    if exists('b:nomod') && b:nomod
        return
    end
    let pos = line('.').' | normal! '.virtcol('.').'|'
    0
    if search(s:timeStampLeader) <= 20 && &modifiable
        let lastdate = matchstr(getline('.'), s:timeStampLeader.'\zs.*')
        let timezone = strftime("%Z")
        let newdate = strftime("%a, %d %b %Y %H:%M:%S %p").' '.timezone
        if lastdate == newdate
            exe pos
            return
        end
        exe 's/'.s:timeStampLeader.'.*/'.s:timeStampLeader.newdate.'/e'
        call s:RemoveLastHistoryItem()
    else
        return
    end
    exe pos
endfunction

augroup LastChange
    au!
    au BufWritePre * :call UpdateWithLastMod()
augroup END

function! <SID>RemoveLastHistoryItem()
  call histdel("/", -1)
  let @/ = histget("/", -1)
endfunction

com! -nargs=0 NOMOD :let b:nomod = 1
com! -nargs=1 MOD   :let b:nomod = 0

filetype plugin on " Enable filetype plugin
filetype indent on
" }
" vim:foldmarker={,} foldlevel=0 foldmethod=marker
```