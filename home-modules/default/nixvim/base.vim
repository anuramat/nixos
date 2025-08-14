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
se nrformats=bin,hex,blank " ^a/^x number formats
se synmaxcol=300
se mouse= " disable mouse


" visuals {{{1
se nowrap
" se mopt=wait:0,history:10000
se nomore
se cmdheight=1
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
se ph=20 " popup max height
se tgc

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
