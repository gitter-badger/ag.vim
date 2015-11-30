#!/bin/bash

case "$1" in --verbose) VERBOSE=1; shift ;; *) VERBOSE=0 ;; esac
VIM=vim

colorecho() { printf "%s" "$(tput setaf $1)${@:2}$(tput sgr0)"; }
getdependencies() {
   rm -rf vader.vim
   git clone -b master --single-branch --depth=1 \
       https://github.com/junegunn/vader.vim && echo
}

urun() { local file="$1" name="$2"
  cp -r ../fixture . && bash ../${name}.sh >/dev/null 2>&1
  eval $VIM -N -u NONE -S ../helper.vim -c 'Vader!' ../${file} \
      $( ((VERBOSE)) || echo '>/dev/null 2>&1' )
}

utest() {
  local file="$1" name="${1%.vader}"
  local title="$(sed -rn '/^"""\s*([^"].*)/ s//\1/p' $file)"
  local expect="$(sed -rn '/^\s*""""\s*/ s///p' $file)"
  local entry="$(colorecho 4 ${name}) ${title}"

  for skp in $SKIP_TESTS; do
    if [[ "$name" == "$skp" ]]; then
      expect="skip"
      break
    fi
  done
  if [[ "$expect" == "skip" ]]; then
    echo "$entry $(colorecho 3 skip)"
    continue
  fi

  tempdir=$(mktemp -d "${name}.XXX")
  trap "rm -rf '$tempdir'" RETURN INT TERM EXIT
  (cd "$tempdir" && urun "$file" "$name")
  RET=$?

  case "$expect"  # TODO:RFC: change return code mechanics -- simplify more
    in failed) ((RET)) && msg="2 failed correctly" || { msg="1 not failed"; RET=1; }
    ;;      *) ((RET)) && { msg="1 ko"; RET=1; }   || msg="2 ok"
  esac
  echo "$entry $(colorecho $msg)"
}

testsuite() {
  getdependencies
  for testcase in *.vader; do
    utest "$testcase"
  done
  echo $(if ((${RET=0}))
  then colorecho '1 some test failed'
  else colorecho '2 test suite passed'
  fi)
  exit $RET
}

if (($#)); then test $@; else testsuite; fi
