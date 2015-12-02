function! s:get_vsel(...)
  " DEV:RFC:ADD: 'range' postfix and use a:firstline, etc -- to exec f once?
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  return a:0 >= 1 ? join(lines, a:1) : lines
endfunction


function! ag#args#derive()
  " TODO: for derived always add -Q -- if don't have option 'treat_as_rgx'
  if visualmode() !=# ''
    return s:get_vsel('\n')
  endif
  " TODO: add -w for words
  let l:args = expand("<cword>")
  if !empty(l:args)
    return l:args
  endif
  return g:last_aggroup
endfunction


function! ag#args#bind(func, args, ...)
  let l:args = (empty(a:args) ? ag#args#derive() : a:args)
  if empty(l:args) | echo "empty search" | return | endif
  " TODO: replace quotes with escaping
  call call(a:func, ['"'.l:args.'"'] + a:000)
endfunction
