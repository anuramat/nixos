" vim: ft=vimscript fdm=marker

" written for nvi 

" vi {{{1
" show cursor position at the bottom of the screen
se ruler
se number
se showmode
" show e v e r y t h i n g
se nolist

" keys {{{1
" command history key
se cedit=
" file completion key
se filec=

" misc {{{1
se tildeop
" skip comment block at the top when opening a file
se comment
" not allowed in nvi
se nomodelines

" brackets {{{1
" highlight matching bracket on insert
se showmatch
se matchtime=1

" wrapping {{{1
" soft wrapping
se noleftright
" hard wrap (max line length)
se wraplen=80

" search {{{1
" egrep style regexes
se noextended 
" ignore case
se ignorecase
" wrap searches
se wrapscan
" smart case regex, incompatible with vim
se iclower
" incremental search
se searchincr

" tabs {{{1
se autoindent
" indentation width for autoindent and </>
se shiftwidth=4
" visual size of a real tab
se tabstop=4
" real tab visual size
se hardtabs=4
