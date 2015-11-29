" NOTE: You must, of course, install ag / the_silver_searcher

" FIXME: Delete deprecated options below on or after 2016-4 (6 months from when the deprecation warning was added) {{{

if exists("g:agprg")
  let g:ag_prg = g:agprg
  echohl WarningMsg
  call input('g:agprg is deprecated and will be removed. Please use g:ag_prg')
  echohl None
endif

if exists("g:aghighlight")
  let g:ag_highlight = g:aghighlight
  echohl WarningMsg
  call input('g:aghighlight is deprecated and will be removed. Please use g:ag_highlight')
  echohl None
endif

if exists("g:agformat")
  let g:ag_format = g:agformat
  echohl WarningMsg
  call input('g:agformat is deprecated and will be removed. Please use g:ag_format')
  echohl None
endif

" }}} FIXME: Delete the deprecated options above on or after 15-7 (6 months from when they were changed)

" Location of the ag utility
if !exists("g:ag_prg")
  " --vimgrep (consistent output we can parse) is available from version  0.25.0+
  if split(system("ag --version"), "[ \n\r\t]")[2] =~ '\d\+.\(\(2[5-9]\)\|\([3-9][0-9]\)\)\(.\d\+\)\?'
    let g:ag_prg="ag --vimgrep"
  else
    " --noheading seems odd here, but see https://github.com/ggreer/the_silver_searcher/issues/361
    let g:ag_prg="ag --column --nogroup --noheading"
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

if !exists("g:ag_nhandler")
  let g:ag_nhandler="botright new"
endif

if !exists("g:ag_mapping_message")
  let g:ag_mapping_message=1
endif

if !exists("g:ag_working_path_mode")
    let g:ag_working_path_mode = 'c'
endif

if !exists("g:ag_goto_exact_line")
  let g:ag_goto_exact_line=0
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

function! ag#VisualSelection(visualmode)
  if a:visualmode
    try
      let a_save = @a
      normal! gv"ay
      return @a
    finally
      let @a = a_save
    endtry
    return ""
endfunction

let g:last_aggroup=""

function! ag#AgGroupLast(ncontext)
  call ag#AgGroup(a:ncontext, 0, '', g:last_aggroup)
endfunction

function! ag#GetArgs(ncontext, visualmode, args)
  if !empty(a:args)
    let l:grepargs = a:args
  else
    if a:visualmode
      let l:grepargs = ag#VisualSelection(a:visualmode)
    else
      let l:grepargs = ""
    endif
    if empty(l:grepargs)
      let l:grepargs = expand("<cword>")
      if empty(l:grepargs)
        let l:grepargs = g:last_aggroup
      endif
    else
      let l:grepargs = '"' . l:grepargs . '"'
    endif
  endif
  return l:grepargs
endfunction

function! ag#AgGroup(ncontext, visualmode, fileregexp, args)
  let l:grepargs = ag#GetArgs(a:ncontext, a:visualmode, a:args)

  if empty(l:grepargs)
     echo "empty search"
     return
  endif

  let g:last_aggroup = l:grepargs

  silent! wincmd P
  if !&previewwindow
    exe g:ag_nhandler
    execute  'resize ' . &previewheight
    set previewwindow
  endif

  setlocal modifiable

  execute "silent %delete_"

  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nowrap

  let context = ''
  if a:ncontext > 0
    let context = '-C' . a:ncontext
  endif

  if empty(a:fileregexp)
    let fileregexp = ''
  else
    let fileregexp = '-G' . a:fileregexp
  endif

  let l:grepargs = substitute(l:grepargs, '#', '\\#','g')
  let l:grepargs = substitute(l:grepargs, '%', '\\%','g')
  "--vimgrep doesn't work well here
  let ag_prg = 'ag'
  execute 'silent read !' . ag_prg . ' -S --group --column ' . context . ' ' . fileregexp . ' ' . l:grepargs
  if !empty(fileregexp) && match(l:grepargs, '\C[A-Z]') == -1
    "explicit file-filter and search in lower case
    syn case ignore
  endif

  syn match agLine /^\d\+:\d\+:/ conceal
  syn match agLineContext /^\d\+-/ conceal
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
  try
    execute 'syn match agSearch /' . escape(l:grepargs, "|()") . '/'
  catch /^Vim\%((\a\+)\)\=:E54/ " invalid regexp
    execute 'syn match agSearch /' . l:grepargs . '/'
  endtry

  highlight link agLine LineNr
  highlight link agFile Question
  highlight link agSearch Todo
  highlight link agLineContext Constant
  setlocal foldmethod=expr
  setlocal foldexpr=FoldAg()
  setlocal foldcolumn=2
  1
  setlocal nomodifiable
  noremap <silent> <buffer> o zaj
  noremap <silent> <buffer> <space> :call NextFold()<CR>
  noremap <silent> <buffer> O :call ToggleEntireFold()<CR>
  noremap <silent> <buffer> <Enter> :call OpenFile(0)<CR>
  noremap <silent> <buffer> s :call OpenFile(1)<CR>
  noremap <silent> <buffer> S :call OpenFile(2)<CR>
  noremap <silent> <buffer> d :call DeleteFold()<CR>
  noremap <silent> <buffer> gl :call ToggleShowLine()<CR>
endfunction

function ToggleShowLine()
  if &conceallevel == 0
    setlocal conceallevel=2
  else
    setlocal conceallevel=0
  endif  
endfunction

function DeleteFold()
  if foldlevel(".") == 0
    return
  endif
  setlocal modifiable
  if foldclosed(".") != -1
    normal zo
  endif
  "normal stops if command fails. On  cursor at beginning of fold motion fails
  normal! [z
  normal! kVj]zD
  setlocal nomodifiable
endfunction

" Find next fold or go back to first one
"
function NextFold()
  let save_a_mark = getpos("'a")
  let mark_a_exists = save_a_mark[1] == 0 
  mark a
  execute 'normal zMzjzo'
  if getpos('.')[1] == getpos("'a")[1]
    "no movement go to first position
    normal gg
    execute 'normal zMzjzo'
  endif  
  if mark_a_exists
    call setpos("'a", save_a_mark)
  else
    delmark a
  endif
endfunction

" Open file for AgGroup selection
"
" forceSplit:
"    0 no
"    1 horizontal
"    2 vertical
"
function! OpenFile(forceSplit)
  let curpos = line('.')
  let line = getline(curpos)
  if empty(line)
    return
  endif

  let increment = 1

  let poscol = curpos
  while line !~ '^\d\+:'
    let poscol = poscol + increment
    let line = getline(poscol)

    if empty(line)
      if increment == -1
        echom 'Cannot find filefor match'
        break
      else
        let increment = -1
      endif
    endif
  endwhile

  let offset = curpos - poscol

  if line =~ '^\d\+:'
    let data = split(line,':')
    let pos = data[0]
    if g:ag_goto_exact_line
      let pos += offset
    endif
    let col = data[1]

    let filename = getline(curpos - 1)
    while !empty(filename) && curpos > 1
      let curpos = curpos - 1
      let filename = getline(curpos - 1)
    endwhile
    let filename = getline(curpos)
    let avaliable_windows = map(filter(range(0, bufnr('$')), 'bufwinnr(v:val)>=0 && buflisted(v:val)'), 'bufwinnr(v:val)')
    let open_command = "edit"
    if a:forceSplit || empty(avaliable_windows)
      if a:forceSplit > 1
        wincmd k
        let open_command = "vertical leftabove vsplit"
      else
        let open_command = "split"
      endif
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

  if empty(l:grepargs)
    echo "Usage: ':Ag {pattern}' (or just :Ag to search for the word under the cursor). See ':help :Ag' for more information."
    return
  endif

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
    if g:ag_working_path_mode ==? 'r' " Try to find the projectroot for current buffer
      let l:cwd_back = getcwd()
      let l:cwd = s:guessProjectRoot()
      try
        exe "lcd ".l:cwd
      catch
        echom 'Failed to change directory to:'.l:cwd
      finally
        silent! execute a:cmd . " " . escape(l:grepargs, '|')
        exe "lcd ".l:cwd_back
      endtry
    else " Someone chose an undefined value or 'c' so we revert to the default
      silent! execute a:cmd . " " . escape(l:grepargs, '|')
    endif
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

  if l:match_count
    if a:cmd =~# '^l'
      exe g:ag_lhandler
      let l:apply_mappings = g:ag_apply_lmappings
      let l:matches_window_prefix = 'l' " we're using the location list
    else
      exe g:ag_qhandler
      let l:apply_mappings = g:ag_apply_qmappings
      let l:matches_window_prefix = 'c' " we're using the quickfix window
    endif
  endif

  " If highlighting is on, highlight the search keyword.
  if exists('g:ag_highlight')
    let @/ = matchstr(a:args, "\\v(-)\@<!(\<)\@<=\\w+|['\"]\\zs.{-}\\ze['\"]")
    call feedkeys(":let &hlsearch=1 \| echo \<CR>", 'n')
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
  else " Close the split window automatically:
    cclose
    lclose
    echohl WarningMsg
    echom 'No matches for "'.a:args.'"'
    echohl None
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
    let p = p.'doc/'
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

function! s:guessProjectRoot()
  let l:splitsearchdir = split(getcwd(), "/")

  while len(l:splitsearchdir) > 2
    let l:searchdir = '/'.join(l:splitsearchdir, '/').'/'
    for l:marker in ['.rootdir', '.git', '.hg', '.svn', 'bzr', '_darcs', 'build.xml']
      " found it! Return the dir
      if filereadable(l:searchdir.l:marker) || isdirectory(l:searchdir.l:marker)
        return l:searchdir
      endif
    endfor
    let l:splitsearchdir = l:splitsearchdir[0:-2] " Splice the list to get rid of the tail directory
  endwhile

  " Nothing found, fallback to current working dir
  return getcwd()
endfunction
