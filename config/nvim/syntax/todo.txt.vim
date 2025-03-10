if exists("b:current_syntax")
    finish
endif

let b:current_syntax = "todo.txt"
syntax match TodoItem /@\S*/
highlight TodoItem guifg=#A0A0A0 ctermfg=LightGray
