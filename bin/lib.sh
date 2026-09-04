# Shared helpers for install.sh and snapshot.sh
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# Yields "repo_path<TAB>live_path<TAB>kind" for every manifest entry.
manifest_entries() {
  grep -vE '^\s*(#|$)' "$REPO/manifest" | while read -r entry; do
    case $entry in
      home/*)   live="$HOME/${entry#home/}" ;;
      system/*) live="/${entry#system/}" ;;
      *) echo "manifest: unknown prefix in '$entry'" >&2; continue ;;
    esac
    kind=file; [[ $entry == */ ]] && kind=dir
    printf '%s\t%s\t%s\n' "$REPO/${entry%/}" "${live%/}" "$kind"
  done
}

# copy_path <src> <dst> <kind>: mirror src onto dst (dirs are synced whole).
copy_path() {
  local src=$1 dst=$2 kind=$3
  mkdir -p "$(dirname "$dst")"
  if [[ $kind == dir ]]; then
    rm -rf "$dst"
    cp -a "$src" "$dst"
    find "$dst" -name '*.bak' -o -name '*.bak.*' | xargs -r rm -f
  else
    cp -p "$src" "$dst"
  fi
}
