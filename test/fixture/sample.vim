function! Foo(bar)
   let hoge = 0
   let fuga = 'bazz'

   if hoge == 0
      echo "hoge is 0"
   else
      echo "hoge is not 0"
   endif

   if fuga =~ 'z'
      echo "fuga contains z"
   else
      echo 'fuga does not contains z'
   endif

   echo 'argument bar is ' . a:bar
endfunction
