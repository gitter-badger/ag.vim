function! ag#paths#lwd()
  return [expand('%:p', 1)]
endfunction


function! ag#paths#buffers()
  let l:bufs = filter(range(1, bufnr('$')), 'buflisted(v:val)')
  let l:files = map(l:bufs, 'fnamemodify(bufname(v:val), ":p")')
  return filter(l:files, '!isdirectory(v:val)')
endfunction


function! ag#paths#help()
  return map(globpath(&runtimepath, 'doc/', 1, 1), 'v:val."*.txt"')
endfunction


function! ag#paths#auto(paths)
  if !empty(a:paths)
    if type(a:paths)==type([]) | return a:paths | endif
    if type(a:paths)==type('') && exists('*ag#paths#'.a:paths)
      return ag#paths#{a:paths}()
    endif
  endif
  return []
endfunction
