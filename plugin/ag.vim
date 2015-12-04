if exists('g:loaded_ag') | finish | endif
let s:cpo_save = &cpo
set cpo&vim

let g:ag_bin=get(g:, 'ag_bin', 'ag')
if !executable(g:ag_bin)
  echoe "Binary '".l:ag_bin."' was not found in your $PATH."
        \."Check if the_silver_searcher is installed and available."
  finish
endif

function! s:cdef(nm, sarg)
  exec 'command! -bang -nargs=* -complete=file '.a:nm
      \.' call ag#bind#dispatch('.a:sarg.')'
endfunction

" FIX: for file -- move flag [-g] from cmd to args field
for f in ['Ag', 'LAg']
  call s:cdef(f.''      , "'".f."', [<f-args>], []       , 'grep<bang>'")
  call s:cdef(f.'Add'   , "'".f."', [<f-args>], []       , 'grepadd<bang>'")
  call s:cdef(f.'Buffer', "'".f."', [<f-args>], 'buffers', 'grep<bang>'")
  call s:cdef(f.'Search', "'".f."', 'slash' , [<f-args>] , 'grep<bang>'")
  call s:cdef(f.'File'  , "'".f."', [<f-args>], []       , 'grep<bang> -g'")
  call s:cdef(f.'Help'  , "'".f."', [<f-args>], 'help'   , 'grep<bang>'")
endfor

let s:f = 'AgGroup'
call s:cdef(s:f.''      , "'".s:f."', [<f-args>], [], 'grep<bang>'")
call s:cdef(s:f.'File'  , "'".s:f."', [<f-args>], [], 'grep<bang> -g'")
unlet s:f
command! -count  AgGroupLast
    \ call ag#AgGroupLast(<count>)


nnoremap <silent> <Plug>(ag-group)  :call ag#AgGroup(v:count, 0, '', '')<CR>
xnoremap <silent> <Plug>(ag-group)  :<C-u>call ag#AgGroup(v:count, 1, '', '')<CR>
nnoremap <silent> <Plug>(ag-group-last)  :call ag#AgGroupLast(v:count)<CR>
" TODO: add <Plug> mappings for Ag* and LAg*


if !(exists("g:ag_no_default_mappings") && g:ag_no_default_mappings)
  let s:ag_mappings = [
    \ ['nx', '<Leader>af', '<Plug>(ag-qf)'],
    \ ['nx', '<Leader>aa', '<Plug>(ag-qf-add)'],
    \ ['nx', '<Leader>ab', '<Plug>(ag-qf-buffer)'],
    \ ['nx', '<Leader>as', '<Plug>(ag-qf-searched)'],
    \ ['nx', '<Leader>aF', '<Plug>(ag-qf-file)'],
    \ ['nx', '<Leader>aH', '<Plug>(ag-qf-help)'],
    \
    \ ['nx', '<Leader>Af', '<Plug>(ag-loc)'],
    \ ['nx', '<Leader>Aa', '<Plug>(ag-loc-add)'],
    \ ['nx', '<Leader>Ab', '<Plug>(ag-loc-buffer)'],
    \ ['nx', '<Leader>AF', '<Plug>(ag-loc-file)'],
    \ ['nx', '<Leader>AH', '<Plug>(ag-loc-help)'],
    \
    \ ['nx', '<Leader>ag', '<Plug>(ag-group)'],
    \ ['n',  '<Leader>ra', '<Plug>(ag-group-last)'],
    \]
endif


if exists('s:ag_mappings')
  for [modes, lhs, rhs] in s:ag_mappings
    for m in split(modes, '\zs')
      if mapcheck(lhs, m) ==# '' && maparg(rhs, m) !=# '' && !hasmapto(rhs, m)
        exe m.'map <silent>' lhs rhs
      endif
    endfor
  endfor
endif


let g:loaded_ag = 1
let &cpo = s:cpo_save
unlet s:cpo_save
