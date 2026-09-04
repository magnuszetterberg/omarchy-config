#!/bin/bash
# Gather the live config into this repo, commit, and push.
#
#   ./sync-config.sh          snapshot + commit + push
#   ./sync-config.sh --check  only report what changed and what is untracked
#
# Runs weekly from the omarchy-config-sync.timer user unit, and can be run by
# hand any time. Also warns about customised files that are not in `manifest`
# yet, so nothing silently falls outside the repo.
set -euo pipefail
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
check_only=no; [[ ${1:-} == --check ]] && check_only=yes
DEFAULTS=/usr/share/omarchy/config

tracked() {  # tracked <path-relative-to-HOME>: is it covered by the manifest?
  local rel=$1 entry
  while read -r entry; do
    entry=${entry#home/}
    [[ $rel == "$entry" || $rel == "${entry%/}"/* ]] && return 0
  done < <(grep -E '^home/' "$REPO/manifest")
  return 1
}
differs_from_default() {  # <path-relative-to-.config>: customised vs Omarchy default?
  [[ -f $DEFAULTS/$1 ]] || return 0
  ! cmp -s "$HOME/.config/$1" "$DEFAULTS/$1"
}

echo "==> Snapshotting tracked files"
"$REPO/bin/snapshot.sh" >/dev/null

echo "==> Looking for customisations not in the manifest"
untracked=()
for f in "$HOME"/.config/hypr/*.lua "$HOME"/.config/hypr/*.conf; do
  [[ -f $f && $f != *.bak* ]] || continue
  rel=.config/hypr/$(basename "$f")
  tracked "$rel" || ! differs_from_default "hypr/$(basename "$f")" || untracked+=("$rel")
done
for f in "$HOME"/.config/omarchy/*.json "$HOME"/.config/omarchy/*.toml "$HOME"/.config/omarchy/extensions/*; do
  [[ -f $f && $f != *.bak* ]] || continue
  rel=${f#"$HOME"/}
  tracked "$rel" || ! differs_from_default "${rel#.config/}" || untracked+=("$rel")
done
for d in "$HOME"/.config/omarchy/plugins/*/ "$HOME"/.config/omarchy/themes/*/; do
  [[ -d $d ]] || continue
  rel=${d#"$HOME"/}; rel=${rel%/}
  tracked "$rel/" || untracked+=("$rel/")
done
for f in "$HOME"/.config/omarchy/hooks/*/*; do
  [[ -f $f && $f != *.sample && $f != *.hook ]] || continue
  rel=${f#"$HOME"/}; tracked "$rel" || untracked+=("$rel")
done
if (( ${#untracked[@]} )); then
  echo "   Not tracked (add to $REPO/manifest as home/<path> if they should be):"
  printf '     %s\n' "${untracked[@]}"
else
  echo "   none"
fi

cd "$REPO"
echo "==> Repo status"
if [[ -z $(git status --porcelain) ]]; then
  echo "   nothing changed since last sync"
  exit 0
fi
git status --short | sed 's/^/   /'
[[ $check_only == yes ]] && exit 0

echo "==> Committing and pushing"
git add -A
git commit -q -m "Sync config $(date +%F)"
if git push -q origin main; then
  echo "   pushed $(git rev-parse --short HEAD)"
  [[ -t 1 ]] || notify-send "omarchy-config" "Config synced to GitHub ($(git rev-parse --short HEAD))" 2>/dev/null || true
else
  echo "   push failed; commit is local, run 'git -C $REPO push' when online" >&2
  [[ -t 1 ]] || notify-send -u critical "omarchy-config" "Config committed but push failed" 2>/dev/null || true
  exit 1
fi
