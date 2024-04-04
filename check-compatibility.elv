#!/usr/bin/env elvish

use re
use str

var elvish_dir
var should_fix

try {
  set elvish_dir = $args[1]
  set should_fix = (==s $args[0] fix)
  if (and (not $should_fix) (!=s $args[0] check)) {
    fail a
  }
} catch {
  echo Usage: (str:split / (src)[name] | put [(all)][-1]) "<check|fix>" "<path to elvish source folder>"
  exit 1
}

fn deps {|file|
  var deps-map = (dissoc [&empty=0] empty)
  var lines = [(from-lines < $file)]
  var in-req-scope = $false
  put $@lines | re:awk {|@line|
    try {
      if $in-req-scope {
        if (eq $line[1] ')') {
          set in-req-scope = $false
          continue
        }
        # echo in scope $line[1] >&2
        # echo map: $deps-map >&2
        set deps-map[$line[1]] = $line[2]
      } elif (eq $line[1] require) {
        if (eq $line[2] '(') {
          set in-req-scope = $true
        } else {
          set deps-map[$line[2]] = $line[3]
        }
      }
    } catch {
      nop
    }
  }
  put $deps-map
}

fn go-version {|file|
  from-lines < $file | each {|line| put (re:find '^go\s+[0-9.]+$' $line)[text]}
}

var go-version-elv
var go-version-mod

try {
  set go-version-elv = (go-version $elvish_dir/go.mod)
  set go-version-mod = (go-version ./go.mod)
} catch e {
  fail "Make sure a go version is specified in both go.mod files"
}
if (!=s $go-version-elv $go-version-mod) {
  if $should_fix {
    echo Updating go version: $go-version-mod '=>' $go-version-elv
    sed -i 's;^go\s\+[0-9.]\+$;'$go-version-elv';' ./go.mod
    or (==s (go-version ./go.mod) $go-version-elv) (fail "Failed to update go version") | nop
  } else {
    fail "Go versions do not match. elvish["$go-version-elv"] | module["$go-version-mod"]"
  }
}

var elvish-deps = (deps $elvish_dir/go.mod)
var module-deps = (deps ./go.mod)

var failed-deps = []

for dep [(keys $module-deps)] {
  echo Checking: $dep
  if (and (has-key $elvish-deps $dep) (!=s $elvish-deps[$dep] $module-deps[$dep])) {
    set failed-deps = [$@failed-deps $dep]
  }
}

if $should_fix {
  for dep $failed-deps {
    go get $dep'@'$elvish-deps[$dep]
  }
  go mod tidy

  echo "Done! Maybe rerun this script using \"check\" to make sure everything should work now."
} else {
  if (!= (count $failed-deps) 0) {
    echo "Dependency mismatch:"
    for dep $failed-deps {
      echo "\tDependency: "$dep' | Elvish: '$elvish-deps[$dep]' | Plugin: '$module-deps[$dep]
    }
    fail "Check your dependencies"
  }
  echo Success!
}

