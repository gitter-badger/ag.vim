#!/bin/bash

VIM=vim

colorecho() { printf "%s" "$(tput setaf $1)${@:2}$(tput sgr0)"; }

getdependencies() {
   rm -rf vader.vim
   git clone -b master --single-branch --depth=1 \
       https://github.com/junegunn/vader.vim
}

test() {
  basenametest=$1
  title="$(sed -rn '/^"""\s*([^"].*)/ s//\1/p' $basenametest.vader)"
  expect="$(sed -rn '/^\s*""""\s*/ s///p' $basenametest.vader)"
  entry="$(colorecho 4 ${basenametest}) ${title}"
  for skp in $SKIP_TESTS; do
    if [[ "$basenametest" == "$skp" ]]; then
      expect="skip"
      break
    fi
  done
  if [[ "$expect" == "skip" ]]; then
    echo "$entry $(colorecho 3 skip)"
    continue
  fi

  tempdir=$(mktemp -d "${basenametest}.XXX")

  cd $tempdir
  cp -r ../fixture .
  bash ../${basenametest}.sh &> /dev/null
  eval $VIM -N -u NONE -S ../helper.vim -c 'Vader!' ../$basenametest.vader \
          $( ((SILENT)) || echo '>/dev/null 2>&1' )
  OK=$?

  cd ..
  rm -rf $tempdir

  case "$expect"
    in failed) ((OK==0)) && { rsp="1 not failed"; OK=1; } || rsp="2 failed correctly"
    ;; *) ((OK==0)) && rsp="2 ok" || { rsp="1 ko"; OK=1; }
  esac
  echo "$entry $(colorecho $rsp)"
}

testsuite() {
  OK=0
  
  getdependencies

  [[ "$1" == '--verbose' ]] && SILENT=1 || SILENT=0

  for testcase in *.vader; do
    basenametest=$(basename $testcase .vader)
    test $basenametest
  done

  echo
  (($OK)) && echo some test failed || echo test suite passed correctly
  exit $OK
}

if [[ "$#" == 0 || "$1" == "--verbose" ]]; then
   testsuite $@
else
   SILENT=1
   test $@
fi
