function! ag#args#vsel(...)
  " DEV:RFC:ADD: 'range' postfix and use a:firstline, etc -- to exec f once?
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  " THINK:NEED: different croping for v/V/C-v
  let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  " TODO: for derived always add -Q -- if don't have option 'treat_as_rgx'
  return a:0 >= 1 ? ['-Q', join(lines, a:1)] : lines
endfunction


function! ag#args#slash()
  " TODO:NEED: more perfect vim->perl regex converter
  let rgx = substitute(getreg('/'), '\(\\<\|\\>\)', '\\b', 'g')
  return [l:rgx]
endfunction


function! ag#args#cword()
  return ['-Qw', expand("<cword>")]
endfunction


" THINK: this vsel disables using ranges?
" ADD: -range to commands to use: '<,'>Ag rgx and 11,87Ag rgx
function! ag#args#auto(args)
  if !empty(a:args)
    if type(a:args)==type([]) | return a:args | endif
    if type(a:args)==type('') && exists('*ag#args#'.a:args)
      return ag#args#{a:args}()
    endif
  endif
  echo 'E' a:args
  return (
    \ (visualmode() !=# '')      ?  ag#args#vsel('\n') :
    \ !empty(expand("<cword>"))  ?  ag#args#cword()    :
    \   g:ag_last.args)
endfunction
