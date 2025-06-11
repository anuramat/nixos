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
nn <leader>q <cmd>call ToggleQuickFix()<cr>
nn <c-j> <cmd>cnext<cr>
nn <c-k> <cmd>cprev<cr>

" formatting {{{1
se shiftround shiftwidth=0 expandtab tabstop=2
se textwidth=80
se formatoptions=qj
" q -- adds comment leader on format
" r -- adds comment leader on newline
" j -- removes leader on line join

" general {{{1
se shada+=r/tmp " no marks
se tildeop
pa cfilter
se complete=t,i,d,.,w,b,u,U " completion source priority
se notimeout " no timeout on key sequences
se keymap=russian-jcukenwin imi=0 " cyrillic on i_^6
se completeopt=menu,menuone,noselect,preview " ins completion
se wildoptions=fuzzy,pum " cmd completion
se fen fdm=indent foldlevelstart=99 " overriden by fdl in modelines
se fdo=block,hor,insert,jump,mark,percent,quickfix,search,tag,undo
" se fcl=all
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
se nowrap
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
se sbr=↪ list lcs=tab:│\ ,extends:❯,precedes:❮,trail:·
au TextYankPost * silent! lua vim.highlight.on_yank()
se number relativenumber
se scrolloff=0 sidescrolloff=30
se report=0 shortmess=CFTWacqst " notification settings
se cursorline cursorlineopt=both
se matchtime=1 showmatch " highlight matching bracket (deciseconds)
se signcolumn=yes " gutter
se winborder=double
let g:nonfiles=['NeogitStatus', 'NeogitPopup', 'oil', 'lazy', 'lspinfo', 'null-ls-info', 'NvimTree', 'neo-tree', 'alpha', 'help', 'fzf']
se ph=20 " popup max height
se notgc
colorscheme default

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

" left and center parts of the status line
function! LM_STL()
  " disentangled
  let left = printf('%s/', substitute(getcwd(), '^' . getenv('HOME'), '~', ''))
  if index(g:nonfiles, &filetype) != -1
    return left
  endif
  let center = expand('%:.')

  " entangle
  if center[0] == '/'
    let left = left . '; '
  endif

  " align
  let width = max([0,(&columns + len(center))/2 - len(left)])

  " join
  return printf("%s%*s", left, width, center)
endfunction

se statusline=%{LM_STL()}%=%S%y%m%r[%c][%P]
se showcmdloc=statusline
