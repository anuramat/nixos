" vim: ft=vim fdm=marker fdl=0

" written for nvi, man 1 vi

" ui {{{1
" show cursor position at the bottom of the screen
se ruler
" line numbers
se number
" show editor mode, and a modified flag
se showmode
" show tabs as ^I and EOL as $
se nolist
" highlight matching bracket on insert
se showmatch
" time for showmatch, deciseconds
se matchtime=1
" #lines about which vi reports changes or yanks
se report=0

" keys {{{1
" command history key
se cedit=
" file completion key
se filec=

" misc {{{1
" make tilde an operator
se tildeop
" skip comment block at the top when opening a shell/c/cpp file
se comment
" recovery files directory (XXX not needed on nixos, try on a different os)
se recdir=/tmp

" wrapping {{{1
" soft wrapping
se noleftright
" hard wrap (max line length)
se wraplen=0
" hard wrap (min distance to right-hand margin)
se wrapmargin=0

" regex {{{1
" egrep style regexes
se noextended
" well, magic
" set magic
" ignore case
se ignorecase
" wrap searches
se wrapscan
" smart case regex
se iclower
" incremental search
se searchincr

" tabs {{{1
" indent on new line
se autoindent
" indentation width for autoindent and shift (</>)
se shiftwidth=4
" width of a hardtab
se tabstop=4
" no idea what this means: "set the spacing between hardware tab settings"
" se hardtabs=4
