#!/bin/bash

VIM=vim

function colorecho() {
   echo -e "\x1b[$1m$2\x1b[m"
}

function getdependencies() {
   rm -rf vader.vim
   git clone https://github.com/junegunn/vader.vim 
}

function test() {
  basenametest=$1
  title="$(grep '^"""[^"]' $basenametest.vader | sed 's/^"""\s*//')"
  expect=$(grep '^\s*""""' $basenametest.vader | sed 's/^""""\s*//')
  for skp in $SKIP_TESTS
  do
    if [ "$basenametest" == "$skp" ]
    then
      expect="skip"
      break
    fi
  done
  if [ "$expect" == "skip" ]
  then
    echo $(colorecho 34 ${basenametest}) "${title}" $(colorecho 33 skip)
    continue
  fi

  tempdir=$(mktemp -d "${basenametest}.XXX")

  cd $tempdir
  cp -r ../fixture .
  bash ../${basenametest}.sh &> /dev/null
  if [ "$SILENT" == 0 ]
  then
     $VIM -N -u NONE -S ../helper.vim -c 'Vader!' ../$basenametest.vader &> /dev/null 
  else
     $VIM -N -u NONE -S ../helper.vim -c 'Vader!' ../$basenametest.vader
  fi

  OK=$? 

  cd ..
  rm -rf $tempdir

  if [ "$OK" == 0 ]
  then
    if [ "$expect" == "failed" ]
    then
      echo $(colorecho 34 ${basenametest}) "${title}" $(colorecho 31 "not failed")
      OK=1
    else
      echo $(colorecho 34 ${basenametest}) "${title}" $(colorecho 32 ok)
    fi
  else
    if [ "$expect" == "failed" ]
    then
      echo $(colorecho 34 ${basenametest}) "${title}" $(colorecho 32 "failed correctly")
    else
      echo $(colorecho 34 ${basenametest}) "${title}" $(colorecho 31 ko)
      OK=1
    fi
  fi
}

function testsuite() {
  OK=0
  
  getdependencies

  if [ "$1" == '--verbose' ] 
  then 
    SILENT=1
  else
    SILENT=0
  fi
  
  for testcase in *.vader
  do
    basenametest=$(basename $testcase .vader)
    test $basenametest
  done
  
  echo
  
  if [ $OK != 0 ]
  then
     echo some test failed
  else
     echo test suite passed correctly
  fi

  exit $OK
}

if [ "$#" == 0 ] || [ "$1" == "--verbose" ]
then
   testsuite $@
else
   SILENT=1
   test $@
fi
