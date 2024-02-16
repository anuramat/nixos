"~~~~~~~~~~~~~~~~~~~~~ basic mappings ~~~~~~~~~~~~~~~~~~~~~"
let mapleader = " "
tnoremap <esc> <c-\><c-n>
xnoremap <leader>p "_dP
nnoremap <c-c> <silent><c-c>
"~~~~~~~~~~~~~~~~~~~~~~~~~~ cmds ~~~~~~~~~~~~~~~~~~~~~~~~~~"
com! KillAll :silent %bd|e#|bd#
"~~~~~~~~~~~~~~~~~~~~~~~ formatting ~~~~~~~~~~~~~~~~~~~~~~~"
se shiftround shiftwidth=0 expandtab tabstop=2
se textwidth=80 formatoptions=qwjr
"~~~~~~~~~~~~~~~~~~~~~~~~~~ misc ~~~~~~~~~~~~~~~~~~~~~~~~~~"
se notimeout " no timeout on key sequences
se keymap=russian-jcukenwin imi=0 " cyrillic on i_^6
se completeopt=menu,menuone,noselect,preview " ins completion
se wildoptions=fuzzy,pum " cmd completion
se nofoldenable foldmethod=indent " folds
se noincsearch smartcase " search settings
se updatetime=100 " period in ms for swap writes and CursorHold autocmd
se undofile " persistent undo
se backupdir-=. " don't write backups to CWD
se virtualedit=block " move beyond line end in v-block mode
pa cfilter
se nf=bin,hex,unsigned " ^a/^x number formats
let g:markdown_fenced_languages = ['python', 'lua', 'vim', 'haskell', 'bash', 'sh', 'json5=json']
" se spl=en,ru " spelling languages (russian will trigger download)
" se pa+=** " recurse in path
"~~~~~~~~~~~~~~~~~~~~~~~~ visuals ~~~~~~~~~~~~~~~~~~~~~~~~~"
se nowrap
se dy=lastline,uhex " XXX idk
se fcs=fold:\ ,foldopen:,foldsep:\ ,foldclose:
se ls=3 " show only one statusline
se sbr=↪ list lcs=tab:│·,extends:❯,precedes:❮,trail:·,lead:·
au TextYankPost * silent! lua vim.highlight.on_yank()
se number relativenumber
se scrolloff=0
se report=0 shortmess=asWIcCF " notification settings
se cursorline cursorlineopt=line
se matchtime=1 showmatch " highlight matching bracket (deciseconds)
se noshowmode " turn off mode indicator in cmdline TODO add mode indicator to "fallback statusline"
se signcolumn=yes " gutter
se tgc " 24-bit color
hi WinSeparator guibg=bg guifg=fg
" hi Normal guibg=NONE " transparent bg (guibg has nothing to do with gui)
if !exists("g:colors_name") " so that we can re-source without changing colorscheme
  try
    colo sorbet
  catch
    colo elflord
  endtry
endif
" pseudo-transparency, looks ugly with transparent bg
if has('nvim')
  se winbl=30 " floating window transparency
  se pb=30 " popup transparency
endif
se ph=20 " popup max height
" hi Normal guibg=NONE " transparent bg (guibg has nothing to do with gui)
let g:netrw_banner=0
" let g:netrw_liststyle=3 " tree style, symlinks are broken tho
let g:netrw_winsize=25
"~~~~~~~~~~~~~~~~~~~~~~~~~ typos ~~~~~~~~~~~~~~~~~~~~~~~~~~"
com! -bang Q q<bang>
com! -bang W w<bang>
com! -bang WQ wq<bang>
com! -bang Wq wq<bang>
com! -bang QA qa<bang>
com! -bang Qa qa<bang>

" vsplit help
cnoreabbrev H vert he


augroup qf
    autocmd!
    autocmd FileType qf set nobuflisted
augroup END
se smc=200 " max column to do syntax hl, might break entire file
let g:matchparen_timeout=50
let g:matchparen_insert_timeout=50

" TODO add defaults
set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc,.png,.jpg

se cb=unnamedplus " unnamedplus for clipboard, unnamed for selection
