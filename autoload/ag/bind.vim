let g:ag_last = {}


function! s:escape(args)
  let l:args = substitute(a:args, '%\|#', '\\&', 'g')
  return '"'.l:args.'"'  " TODO: replace quotes with escaping
endfunction


" USE: for repeat
function! ag#bind#call()
  " FIND: another way -- to execute args list directly without join?
  echo join(map(g:ag_last.args + g:ag_last.paths, '<SID>escape(v:val)'))
  call {g:ag_last.func}(
        \ join(map(g:ag_last.args + g:ag_last.paths, '<SID>escape(v:val)')),
        \ g:ag_last.cmd)
endfunction


" THINK: separate flags and regex?
function! ag#bind#dispatch(func, args, paths, cmd)
  let l:args = ag#args#auto(a:args)
  if empty(l:args) | echo "empty search" | return | endif

  let g:ag_last.func = 'ag#'.(exists('*ag#'.a:func) ? a:func : 'Ag')
  let g:ag_last.args = l:args
  let g:ag_last.paths  = ag#paths#auto(a:paths)
  let g:ag_last.cmd  = a:cmd

  " echo g:ag_last
  call ag#bind#call()
endfunction
