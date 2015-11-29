if exists('g:loaded_ag') | finish | else | let g:loaded_ag = 1 | endif
let s:cpo_save = &cpo
set cpo&vim

" NOTE: You must, of course, install ag / the_silver_searcher
command! -bang -nargs=* -complete=file Ag call ag#Ag('grep<bang>',<q-args>)
command! -bang -nargs=* -complete=file AgBuffer call ag#AgBuffer('grep<bang>',<q-args>)
command! -count -nargs=*               AgGroup call     ag#AgGroup(<count>, 0, '', <q-args>)
command! -count -nargs=*               AgGroupFile call ag#AgGroup(<count>, 0, <f-args>)
command! -count                        AgGroupLast call ag#AgGroupLast(<count>)
command! -bang -nargs=* -complete=file AgAdd call ag#Ag('grepadd<bang>', <q-args>)
command! -bang -nargs=* -complete=file AgFromSearch call ag#AgFromSearch('grep<bang>', <q-args>)
command! -bang -nargs=* -complete=file LAg call ag#Ag('lgrep<bang>', <q-args>)
command! -bang -nargs=* -complete=file LAgBuffer call ag#AgBuffer('lgrep<bang>',<q-args>)
command! -bang -nargs=* -complete=file LAgAdd call ag#Ag('lgrepadd<bang>', <q-args>)
command! -bang -nargs=* -complete=file AgFile call ag#Ag('grep<bang> -g', <q-args>)
command! -bang -nargs=* -complete=help AgHelp call ag#AgHelp('grep<bang>',<q-args>)
command! -bang -nargs=* -complete=help LAgHelp call ag#AgHelp('lgrep<bang>',<q-args>)


nnoremap <silent> <Plug>(ag-group)  :call ag#AgGroup(v:count, 0, '', '')<CR>
xnoremap <silent> <Plug>(ag-group)  :<C-u>call ag#AgGroup(v:count, 1, '', '')<CR>
nnoremap <silent> <Plug>(ag-group-last)  :call ag#AgGroupLast(v:count)<CR>


if !(exists("g:ag_no_default_mappings") && g:ag_no_default_mappings)
  let s:ag_mappings = [
    \ ['nx', '<Leader>ag', '<Plug>(ag-group)'],
    \ ['n',  '<Leader>ra', '<Plug>(ag-group-last)'],
    \]
endif


if exists('s:ag_mappings')
  for [modes, lhs, rhs] in s:ag_mappings
    for m in split(modes, '\zs')
      if !hasmapto(rhs, m) && mapcheck(lhs, m) ==# ''
        exe m.'map <silent>' lhs rhs
      endif
    endfor
  endfor
endif


let &cpo = s:cpo_save
unlet s:cpo_save
