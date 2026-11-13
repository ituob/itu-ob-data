#!/usr/bin/env bash
# Fails when a change between two commits rewrites the patch log.
# ob-issues/ is append-only: corrections are new patch files, never edits,
# deletions or renames of existing ones (ituob/ituob.github.io#103). A new
# issue may also add its ob-issues/{issue}/meta.yaml; the gate chain
# validates its shape.
# Usage: check-patch-log.sh BASE_SHA HEAD_SHA
set -euo pipefail

base="$1"
head="$2"
name='^ob-issues/[1-9][0-9]*/[a-z][a-z0-9-]*/[0-9]{3}-(ADD|SUP|REP|LIR|MOD|DEL|SEED)\.yaml$'
meta='^ob-issues/[1-9][0-9]*/meta\.yaml$'
status=0

while IFS=$'\t' read -r change path; do
  [ -z "$change" ] && continue
  if [ "$change" != "A" ]; then
    echo "::error file=$path::patch log is append-only; $path was changed ($change). Add a new patch instead."
    status=1
  elif ! [[ "$path" =~ $name || "$path" =~ $meta ]]; then
    echo "::error file=$path::$path is neither ob-issues/{issue}/{register}/NNN-TYPE.yaml nor ob-issues/{issue}/meta.yaml"
    status=1
  else
    echo "authored patch: $path"
  fi
done < <(git diff --name-status --no-renames "$base" "$head" -- ob-issues/)

exit "$status"
