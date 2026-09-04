#!/bin/bash
# Restore this config onto a fresh Omarchy install.
#
#   bin/install.sh            copy the home-directory files into place
#   sudo bin/install.sh --system   install the root-owned files (power caps service)
#
# Existing files are backed up next to themselves as <name>.bak.<timestamp>.
set -euo pipefail
source "$(dirname "$0")/lib.sh"
mode=${1:-home}
stamp=$(date +%s)

case $mode in
  home|--home)
    [[ $EUID -eq 0 ]] && { echo "run the home install as your user, not root" >&2; exit 1; }
    manifest_entries | while IFS=$'\t' read -r src dst kind; do
      [[ $src == "$REPO/home/"* ]] || continue
      if [[ -e $dst && $kind == file ]] && ! cmp -s "$src" "$dst"; then
        cp -p "$dst" "$dst.bak.$stamp"; echo "backup  $dst.bak.$stamp"
      fi
      copy_path "$src" "$dst" "$kind"; echo "install $dst"
    done
    chmod +x "$HOME"/.local/share/omarchy-overrides/bin/*
    echo
    echo "Reloading Hyprland and the Omarchy shell..."
    hyprctl reload >/dev/null 2>&1 || true
    omarchy restart shell >/dev/null 2>&1 || true
    echo "Done. Log out and back in once so the override PATH from uwsm/env.d applies."
    echo "Then run:  sudo $REPO/bin/install.sh --system"
    ;;
  system|--system)
    [[ $EUID -eq 0 ]] || { echo "run with sudo: sudo $0 --system" >&2; exit 1; }
    manifest_entries | while IFS=$'\t' read -r src dst kind; do
      [[ $src == "$REPO/system/"* ]] || continue
      copy_path "$src" "$dst" "$kind"; echo "install $dst"
    done
    chmod 755 /usr/local/bin/zbook-power-caps
    chmod 440 /etc/sudoers.d/zbook-power-caps; chown root:root /etc/sudoers.d/zbook-power-caps
    visudo -cf /etc/sudoers.d/zbook-power-caps >/dev/null
    systemctl daemon-reload
    udevadm control --reload-rules
    systemctl enable --now zbook-power-caps.service
    echo; /usr/local/bin/zbook-power-caps status
    ;;
  *) echo "usage: $0 [--home|--system]" >&2; exit 1 ;;
esac
