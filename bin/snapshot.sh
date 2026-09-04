#!/bin/bash
# Pull the live files back into the repo so they can be committed.
# Root-owned system files are read with sudo only if they are unreadable.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
manifest_entries | while IFS=$'\t' read -r src dst kind; do
  if [[ -r $dst ]]; then
    copy_path "$dst" "$src" "$kind"
  elif [[ $dst == /etc/* || $dst == /usr/* ]]; then
    # Root-only files (the sudoers rule) are authored in the repo and only ever
    # installed from it, so keep the repo copy unless passwordless sudo is at hand.
    if [[ -t 0 ]] && sudo -n true 2>/dev/null && sudo -n test -e "$dst"; then
      mkdir -p "$(dirname "$src")"; sudo -n cat "$dst" > "$src"
    else
      echo "root-only, kept repo copy: $dst"
    fi
  else
    echo "missing $dst (skipped)"
  fi
done
cd "$REPO"
echo; git status --short; echo
echo "Review with 'git diff', then commit:  git -C $REPO commit -am 'Update config'"
