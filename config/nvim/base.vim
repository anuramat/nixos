" vim: fdm=marker fdl=0
" TODO: maybe remove bangs where not necessary?

" mappings {{{1
let mapleader = " "
let maplocalleader = mapleader . ";"
tno <esc> <c-\><c-n>
nn <c-c> <silent><c-c>
function! ToggleQuickFix()
    if empty(filter(getwininfo(), 'v:val.quickfix'))
        copen
    else
        cclose
    endif
endfunction
nn <silent> <leader>q :call ToggleQuickFix()<cr>

" formatting {{{1
se shiftround shiftwidth=0 expandtab tabstop=2
se textwidth=80 formatoptions=qjr
se nowrap

" general {{{1
pa cfilter
se complete=t,i,d,.,w,b,u,U " completion source priority
se clipboard=unnamedplus " unnamedplus for clipboard, unnamed for selection
se notimeout " no timeout on key sequences
se keymap=russian-jcukenwin imi=0 " cyrillic on i_^6
se completeopt=menu,menuone,noselect,preview " ins completion
se wildoptions=fuzzy,pum " cmd completion
se fen fdm=indent foldlevelstart=99 " overriden by fdl in modelines
se foldopen=insert,mark,quickfix,search,tag " maybe undo too?
se incsearch ignorecase smartcase " search
se updatetime=100 " period in ms for swap writes and CursorHold autocmd
se undofile " persistent undo
se backupdir-=. " don't write backups to CWD
se virtualedit=block " move beyond line end in v-block mode
" se nrformats=bin,hex,blank " ^a/^x number formats " TODO wait until blank gets merged into stable
se nrformats=bin,hex,unsigned " ^a/^x number formats
let g:markdown_fenced_languages = ['python', 'lua', 'vim', 'haskell', 'bash', 'sh', 'json5=json', 'tex']
se synmaxcol=300
" se spl=en,ru " spelling languages (russian will trigger download)
" se path+=** " recurse in path - bad idea
se mouse= " disable mouse

" shell {{{2
" se shcf=-ic " use an interactive shell for "!" so that background jobs work
" source everything; breaks plenary:
" let &shell='/usr/bin/env bash --login'
" TODO figure out
" }}}

" visuals {{{1
let g:matchparen_timeout=50
let g:matchparen_insert_timeout=50
" se mopt=wait:0,history:10000
se nomore
se cmdheight=1
" tree style, symlinks are broken tho: https://github.com/neovim/neovim/issues/27301
" let g:netrw_liststyle=3 
let g:netrw_banner=0
let g:netrw_winsize=25
se cole=0
se fcs=fold:\─,foldopen:,foldsep:\ ,foldclose:
se foldtext=
se laststatus=3 " show only one statusline
se sbr=↪ list lcs=tab:├─,extends:❯,precedes:❮,trail:·,lead:·
" i		jjdfsd
au TextYankPost * silent! lua vim.highlight.on_yank()
se number relativenumber
se scrolloff=0 sidescrolloff=30
se report=0 shortmess=CFISTWacqst " notification settings, I for intro
se cursorline cursorlineopt=both
se matchtime=1 showmatch " highlight matching bracket (deciseconds)
se signcolumn=yes " gutter
let g:border="rounded" " none/single/double/rounded/solid/shadow/array; used in plug cfgs; `:he nvim_open_win`
let g:nonfiles=['NeogitStatus', 'NeogitPopup', 'oil', 'lazy', 'lspinfo', 'null-ls-info', 'NvimTree', 'neo-tree', 'alpha', 'help']
se ph=20 " popup max height

" fallback colorscheme {{{2
if !exists("g:colors_name") " so that we can re-source without changing colorscheme
  try
    colo sorbet
  catch
    colo elflord
  endtry
endif

" pseudo/transparency, sucks in terminal {{{2
" se winbl=30 " floating window transparency
" se pb=30 " popup transparency
" }}}

" typos {{{1
com! -bang Q q<bang>
com! -bang W w<bang>
com! -bang WQ wq<bang>
com! -bang Wq wq<bang>
com! -bang Wqa wqa<bang>
com! -bang WQa wqa<bang>
com! -bang WQA wqa<bang>
com! -bang QA qa<bang>
com! -bang Qa qa<bang>

" commands {{{1

" open messages in a buffer {{{2
com! Messages call MessageBuffer()
function! MessageBuffer()
  let messages = execute('messages')
  execute 'enew'
  call setline(1, split(messages, "\n"))
  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal nobuflisted
  setlocal nomodifiable
endfunction

" todo.txt {{{2
" trim spaces
com! Trim %s/\ \+$//g
" sort todo.txt by projects
com! SortProj sort /\v(^|\s)\zs\+\S+\ze/ r
" }}}

" misc {{{1
" hide qf buffers:
augroup qf
  autocmd!
  autocmd FileType qf set nobuflisted
augroup END
" use ripgrep
se grepprg=rg\ --vimgrep
se grepformat=%f:%l:%c:%m
