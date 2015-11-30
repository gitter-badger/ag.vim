#!/bin/bash
cd $(dirname $(readlink -m ${0}))

case "$1" in -v|--verbose) VERBOSE=1; shift ;; *) VERBOSE=0 ;; esac
VIM=vim

color() { printf "%s" "$(tput setaf $1)${@:2}$(tput sgr0)"; }
get_deps() {
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
  local entry="$(color 4 ${name}) ${title}"

  if [[ " $SKIP_TESTS " =~ " $name " ]]; then
    echo "$entry $(color 3 skip)"; continue
  fi

  tempdir=$(mktemp -d "${name}.XXX")
  trap "rm -rf '$tempdir'" RETURN INT TERM EXIT
  (cd "$tempdir" && urun "$file" "$name")
  RET=$?

  case "$expect"  # TODO:RFC: change return code mechanics -- simplify more
    in failed) ((RET)) && msg="2 failed correctly" || { msg="1 not failed"; RET=1; }
    ;;      *) ((RET)) && { msg="1 ko"; RET=1; }   || msg="2 ok"
  esac
  echo "$entry $(color $msg)"
}

testsuite() {
  for testcase in *.vader; do
    utest "$testcase"
  done
  echo $(if ((${RET=0}))
  then color '1 some test failed'
  else color '2 test suite passed'
  fi)
  return $RET
}

if (($#)); then utest $@; else get_deps && testsuite; fi
