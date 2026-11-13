#!/usr/bin/env bash
# Exercises check-patch-log.sh against a throwaway git repository.
set -euo pipefail

check="$(cd "$(dirname "$0")" && pwd)/check-patch-log.sh"
repo="$(mktemp -d)"
trap 'rm -rf "$repo"' EXIT
cd "$repo"
git init -q
git config user.email ci@example.invalid
git config user.name ci
mkdir -p ob-issues/1170/e212-mnc
echo "type: ADD" > ob-issues/1170/e212-mnc/001-ADD.yaml
git add . && git commit -qm base
base="$(git rev-parse HEAD)"

expect() { # expect PASS|FAIL description
  local want="$1" what="$2" got=PASS
  "$check" "$base" HEAD > /dev/null || got=FAIL
  if [ "$got" != "$want" ]; then
    echo "not ok: $what (wanted $want, got $got)"
    exit 1
  fi
  echo "ok: $what"
  git reset -q --hard "$base"
}

echo "type: SUP" > ob-issues/1170/e212-mnc/002-SUP.yaml
git add . && git commit -qm add
expect PASS "a new patch file is accepted"

echo "type: REP" > ob-issues/1170/e212-mnc/001-ADD.yaml
git commit -qam edit
expect FAIL "editing an existing patch is rejected"

git rm -q ob-issues/1170/e212-mnc/001-ADD.yaml && git commit -qm delete
expect FAIL "deleting a patch is rejected"

git mv ob-issues/1170/e212-mnc/001-ADD.yaml ob-issues/1170/e212-mnc/009-ADD.yaml
git commit -qm rename
expect FAIL "renaming a patch is rejected"

echo "x: 1" > ob-issues/1170/e212-mnc/data.yaml
git add . && git commit -qm fullstate
expect FAIL "a file that is not a NNN-TYPE patch is rejected"

echo "unrelated" > README.adoc
git add . && git commit -qm other
expect PASS "changes outside ob-issues are ignored"
