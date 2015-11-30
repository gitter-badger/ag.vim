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
  title="$(grep '^"""[^"]' $basenametest.vader | sed 's/^"""\s*//')"
  expect=$(grep '^\s*""""' $basenametest.vader | sed 's/^""""\s*//')
  for skp in $SKIP_TESTS; do
    if [[ "$basenametest" == "$skp" ]]; then
      expect="skip"
      break
    fi
  done
  if [[ "$expect" == "skip" ]]; then
    echo $(colorecho 4 ${basenametest}) "${title}" $(colorecho 3 skip)
    continue
  fi

  tempdir=$(mktemp -d "${basenametest}.XXX")

  cd $tempdir
  cp -r ../fixture .
  bash ../${basenametest}.sh &> /dev/null
  if [[ "$SILENT" == 0 ]]
  then
     $VIM -N -u NONE -S ../helper.vim -c 'Vader!' ../$basenametest.vader &> /dev/null 
  else
     $VIM -N -u NONE -S ../helper.vim -c 'Vader!' ../$basenametest.vader
  fi

  OK=$? 

  cd ..
  rm -rf $tempdir

  if [[ "$OK" == 0 ]]
  then
    if [[ "$expect" == "failed" ]]
    then
      echo $(colorecho 4 ${basenametest}) "${title}" $(colorecho 1 "not failed")
      OK=1
    else
      echo $(colorecho 4 ${basenametest}) "${title}" $(colorecho 2 ok)
    fi
  else
    if [[ "$expect" == "failed" ]]
    then
      echo $(colorecho 4 ${basenametest}) "${title}" $(colorecho 2 "failed correctly")
    else
      echo $(colorecho 4 ${basenametest}) "${title}" $(colorecho 1 ko)
      OK=1
    fi
  fi
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
