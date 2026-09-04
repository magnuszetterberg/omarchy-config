#!/bin/bash
# Pull the live files back into the repo so they can be committed.
# Root-owned system files are read with sudo only if they are unreadable.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
manifest_entries | while IFS=$'\t' read -r src dst kind; do
  if [[ ! -e $dst ]]; then echo "missing $dst (skipped)"; continue; fi
  if [[ -r $dst ]]; then
    copy_path "$dst" "$src" "$kind"
  else
    mkdir -p "$(dirname "$src")"; sudo cat "$dst" > "$src"
  fi
done
cd "$REPO"
echo; git status --short; echo
echo "Review with 'git diff', then commit:  git -C $REPO commit -am 'Update config'"
