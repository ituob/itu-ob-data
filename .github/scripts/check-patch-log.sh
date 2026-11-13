#!/usr/bin/env bash
# Fails when a change between two commits rewrites the patch log.
# ob-issues/ is append-only: corrections are new patch files, never edits,
# deletions or renames of existing ones (ituob/ituob.github.io#103).
# Usage: check-patch-log.sh BASE_SHA HEAD_SHA
set -euo pipefail

base="$1"
head="$2"
name='^ob-issues/[0-9]+/[a-z0-9-]+/[0-9]{3}-(ADD|SUP|REP|LIR|MOD|DEL|SEED)\.yaml$'
status=0

while IFS=$'\t' read -r change path; do
  [ -z "$change" ] && continue
  if [ "$change" != "A" ]; then
    echo "::error file=$path::patch log is append-only; $path was changed ($change). Add a new patch instead."
    status=1
  elif ! [[ "$path" =~ $name ]]; then
    echo "::error file=$path::$path does not match ob-issues/{issue}/{register}/NNN-TYPE.yaml"
    status=1
  else
    echo "authored patch: $path"
  fi
done < <(git diff --name-status --no-renames "$base" "$head" -- ob-issues/)

exit "$status"
