" NOTE: You must, of course, install ag / the_silver_searcher

" FIXME: Delete deprecated options below on or after 15-7 (6 months from when they were changed) {{{

if exists("g:agprg")
  let g:ag_prg = g:agprg
endif

if exists("g:aghighlight")
  let g:ag_highlight = g:aghighlight
endif

if exists("g:agformat")
  let g:ag_format = g:agformat
endif

" }}} FIXME: Delete the deprecated options above on or after 15-7 (6 months from when they were changed)

" Location of the ag utility
if !exists("g:ag_prg")
  " --vimgrep (consistent output we can parse) is available from version  0.25.0+
  if split(system("ag --version"), "[ \n\r\t]")[2] =~ '\d\+.\(2[5-9]\|[3-9]\d\)\(.\d\+\)\?'
    let g:ag_prg="ag --vimgrep"
  else
    let g:ag_prg="ag --column"
  endif
endif

if !exists("g:ag_apply_qmappings")
  let g:ag_apply_qmappings=1
endif

if !exists("g:ag_apply_lmappings")
  let g:ag_apply_lmappings=1
endif

if !exists("g:ag_qhandler")
  let g:ag_qhandler="botright copen"
endif

if !exists("g:ag_lhandler")
  let g:ag_lhandler="botright lopen"
endif

if !exists("g:ag_mapping_message")
  let g:ag_mapping_message=1
endif

function! ag#AgBuffer(cmd, args)
  let l:bufs = filter(range(1, bufnr('$')), 'buflisted(v:val)')
  let l:files = []
  for buf in l:bufs
    let l:file = fnamemodify(bufname(buf), ':p')
    if !isdirectory(l:file)
      call add(l:files, l:file)
    endif
  endfor
  call ag#Ag(a:cmd, a:args . ' ' . join(l:files, ' '))
endfunction

function! ag#VisualSelection(mode)
  if a:mode =~ "^[vV]" 
    try
      let a_save = @a
      normal! gv"ay
      return @a
    finally
      let @a = a_save
    endtry
  else
    return ""
  endif
endfunction

let g:last_aggroup=""

function! ag#AgGroupLast(ncontext)
  call ag#AgGroup(a:ncontext, '', g:last_aggroup)
endfunction

function! ag#AgGroup(ncontext, mode, args)
  if !empty(a:args)
    let l:grepargs = a:args
  else
    let l:grepargs = ag#VisualSelection(a:mode) 
    if empty(l:grepargs)
      let l:grepargs = expand("<cword>")
      if empty(l:grepargs)
        let l:grepargs = g:last_aggroup
      endif
    else
      let l:grepargs = '"' . l:grepargs . '"'
    endif
  end

  if empty(l:grepargs)
     echo "empty search"
     return
  endif

  let g:last_aggroup = l:grepargs

  silent! wincmd P
  if !&previewwindow
    execute 'bo ' . &previewheight . ' new'
    set previewwindow
  endif

  setlocal modifiable

  execute "silent %delete_"
  
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nowrap

  let context = ''
  if a:ncontext > 0
    let context = '-C' . a:ncontext 
  endif

  let l:grepargs = substitute(l:grepargs, '#', '\\#','g')
  let l:grepargs = substitute(l:grepargs, '%', '\\%','g')
  execute 'silent read !ag --group --column ' . context . ' '. l:grepargs
  syn match agLine /^\d\+:\d\+\(:\)\@=/
  syn match agLineContext /^\d\+-/
  syn match agFile /^\n.\+$/hs=s+1
  if hlexists('agSearch')
    silent syn clear agSearch
  endif
  if l:grepargs =~ '^"'
    "detect "find me" file1 file2
    let l:grepargs = split(l:grepargs, '"')[0]
  else
    let l:grepargs = split(l:grepargs, '\s\+')[0]
  endif
  let l:grepargs = substitute(l:grepargs, '/', '\\/', 'g')
  execute 'syn match agSearch /' . l:grepargs . '/'
  highlight link agLine LineNr
  highlight link agFile Question
  highlight link agSearch Todo
  highlight link agLineContext Constant
  setlocal foldmethod=expr
  setlocal foldexpr=FoldAg()
  setlocal foldcolumn=2
  1
  setlocal nomodifiable
  map <buffer> o za
  map <buffer> <space> zMzjzo
  map <buffer> O :call ToggleEntireFold()<CR>
  map <buffer> <Enter> :call OpenFile()<CR>
endfunction

function! OpenFile()
  let curpos = line('.')
  let line = getline(curpos)
  if empty(line)
    return
  endif

  let poscol = curpos
  while line !~ '^\d\+:'
    let poscol = poscol + 1
    let line = getline(poscol)
  endwhile

  if line =~ '^\d\+:'
    let data = split(line,':')
    let pos = data[0]
    let col = data[1]

    let filename = getline(curpos - 1)
    while !empty(filename) && curpos > 1
      let curpos = curpos - 1
      let filename = getline(curpos - 1)
    endwhile
    let filename = getline(curpos)
    let avaliable_windows = map(filter(range(0, bufnr('$')), 'bufwinnr(v:val)>=0 && buflisted(v:val)'), 'bufwinnr(v:val)')
    let open_command = "edit"
    if (empty(avaliable_windows))
      let open_command = "split"
    else
      let winnr = get(avaliable_windows, 0)
      exe winnr . "wincmd w"
    endif
    exe open_command . ' +' . pos . ' ' . filename
    exe 'normal ' . col . '|'
    exe 'normal zv'
  endif
endfunction

function! ToggleEntireFold()
  if foldclosed(2) == -1
    normal zM
  else
    normal zR
  endif
endfunction

function! FoldAg()
  let line = getline(v:lnum)
  if empty(line)
    return '0'
  else
    return '1'
  endif
  return '0'
endfunction

function! ag#Ag(cmd, args)
  let l:ag_executable = get(split(g:ag_prg, " "), 0)

  " Ensure that `ag` is installed
  if !executable(l:ag_executable)
    echoe "Ag command '" . l:ag_executable . "' was not found. Is the silver searcher installed and on your $PATH?"
    return
  endif

  " If no pattern is provided, search for the word under the cursor
  if empty(a:args)
    let l:grepargs = expand("<cword>")
  else
    let l:grepargs = a:args
  end

  " Format, used to manage column jump
  if a:cmd =~# '-g$'
    let s:ag_format_backup=g:ag_format
    let g:ag_format="%f"
  elseif exists("s:ag_format_backup")
    let g:ag_format=s:ag_format_backup
  elseif !exists("g:ag_format")
    let g:ag_format="%f:%l:%c:%m"
  endif

  let l:grepprg_bak=&grepprg
  let l:grepformat_bak=&grepformat
  let l:t_ti_bak=&t_ti
  let l:t_te_bak=&t_te
  try
    let &grepprg=g:ag_prg
    let &grepformat=g:ag_format
    set t_ti=
    set t_te=
    silent! execute a:cmd . " " . escape(l:grepargs, '|')
  finally
    let &grepprg=l:grepprg_bak
    let &grepformat=l:grepformat_bak
    let &t_ti=l:t_ti_bak
    let &t_te=l:t_te_bak
  endtry

  if a:cmd =~# '^l'
    let l:match_count = len(getloclist(winnr()))
  else
    let l:match_count = len(getqflist())
  endif

  if a:cmd =~# '^l' && l:match_count
    exe g:ag_lhandler
    let l:apply_mappings = g:ag_apply_lmappings
    let l:matches_window_prefix = 'l' " we're using the location list
  elseif l:match_count
    exe g:ag_qhandler
    let l:apply_mappings = g:ag_apply_qmappings
    let l:matches_window_prefix = 'c' " we're using the quickfix window
  endif

  " If highlighting is on, highlight the search keyword.
  if exists("g:ag_highlight")
    let @/=a:args
    set hlsearch
  end

  redraw!

  if l:match_count
    if l:apply_mappings
      nnoremap <silent> <buffer> h  <C-W><CR><C-w>K
      nnoremap <silent> <buffer> H  <C-W><CR><C-w>K<C-w>b
      nnoremap <silent> <buffer> o  <CR>
      nnoremap <silent> <buffer> t  <C-w><CR><C-w>T
      nnoremap <silent> <buffer> T  <C-w><CR><C-w>TgT<C-W><C-W>
      nnoremap <silent> <buffer> v  <C-w><CR><C-w>H<C-W>b<C-W>J<C-W>t

      exe 'nnoremap <silent> <buffer> e <CR><C-w><C-w>:' . l:matches_window_prefix .'close<CR>'
      exe 'nnoremap <silent> <buffer> go <CR>:' . l:matches_window_prefix . 'open<CR>'
      exe 'nnoremap <silent> <buffer> q  :' . l:matches_window_prefix . 'close<CR>'

      exe 'nnoremap <silent> <buffer> gv :let b:height=winheight(0)<CR><C-w><CR><C-w>H:' . l:matches_window_prefix . 'open<CR><C-w>J:exe printf(":normal %d\<lt>c-w>_", b:height)<CR>'
      " Interpretation:
      " :let b:height=winheight(0)<CR>                      Get the height of the quickfix/location list window
      " <CR><C-w>                                           Open the current item in a new split
      " <C-w>H                                              Slam the newly opened window against the left edge
      " :copen<CR> -or- :lopen<CR>                          Open either the quickfix window or the location list (whichever we were using)
      " <C-w>J                                              Slam the quickfix/location list window against the bottom edge
      " :exe printf(":normal %d\<lt>c-w>_", b:height)<CR>   Restore the quickfix/location list window's height from before we opened the match

      if g:ag_mapping_message && l:apply_mappings
        echom "ag.vim keys: q=quit <cr>/e/t/h/v=enter/edit/tab/split/vsplit go/T/H/gv=preview versions of same"
      endif
    endif
  else
    echom 'No matches for "'.a:args.'"'
  endif
endfunction

function! ag#AgFromSearch(cmd, args)
  let search =  getreg('/')
  " translate vim regular expression to perl regular expression.
  let search = substitute(search,'\(\\<\|\\>\)','\\b','g')
  call ag#Ag(a:cmd, '"' .  search .'" '. a:args)
endfunction

function! ag#GetDocLocations()
  let dp = ''
  for p in split(&runtimepath,',')
    let p = p.'/doc/'
    if isdirectory(p)
      let dp = p.'*.txt '.dp
    endif
  endfor
  return dp
endfunction

function! ag#AgHelp(cmd,args)
  let args = a:args.' '.ag#GetDocLocations()
  call ag#Ag(a:cmd,args)
endfunction
