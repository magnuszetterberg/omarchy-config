#!/bin/bash
# Pull the live files back into the repo so they can be committed.
# Root-owned system files are read with sudo only if they are unreadable.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
manifest_entries | while IFS=$'\t' read -r src dst kind; do
  if [[ -r $dst ]]; then
    copy_path "$dst" "$src" "$kind"
  elif [[ $dst == /etc/* || $dst == /usr/* ]] && sudo test -e "$dst"; then
    # root-only files such as the sudoers rule
    mkdir -p "$(dirname "$src")"; sudo cat "$dst" > "$src"
  else
    echo "missing $dst (skipped)"
  fi
done
cd "$REPO"
echo; git status --short; echo
echo "Review with 'git diff', then commit:  git -C $REPO commit -am 'Update config'"
