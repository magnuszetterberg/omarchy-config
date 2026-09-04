#!/bin/bash
# One-shot setup of a fresh Omarchy install from this repo:
#   1. installs the packages the tweaks depend on
#   2. copies the home-directory files into place
#   3. installs the root-owned files (asks for your sudo password once)
#   4. activates the Combitech theme
#
#   ./install-config.sh                 full setup
#   ./install-config.sh --skip-system   everything except the sudo part
set -euo pipefail
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export OMARCHY_CONFIG_WRAPPED=1
skip_system=no
[[ ${1:-} == --skip-system ]] && skip_system=yes

step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

step "Packages"
# zellij: foot opens straight into it. rsync is not needed by the scripts here.
if command -v omarchy >/dev/null; then
  omarchy pkg add zellij
else
  sudo pacman -S --needed --noconfirm zellij
fi

step "Home-directory files"
"$REPO/bin/install.sh" --home

if [[ $skip_system == no ]]; then
  step "Root-owned files (CPU power caps service, sudoers rule)"
  sudo "$REPO/bin/install.sh" --system
fi

step "Weekly sync timer"
systemctl --user daemon-reload
systemctl --user enable --now omarchy-config-sync.timer

step "Theme"
if command -v omarchy >/dev/null && [[ -d $HOME/.config/omarchy/themes/combitech ]]; then
  omarchy theme set combitech || echo "theme set failed; run 'omarchy theme set combitech' later"
fi

step "Done"
cat <<MSG
Log out and back in once so the override PATH from ~/.config/uwsm/env.d applies
(the launcher hints and screensaver override depend on it).

Afterwards:
  - the battery panel in the bar shows the "Are u nuts?" power profile
  - Super+/ rescales monitors and re-reads monitors.lua
  - foot opens into zellij with the keybinding cheatsheet
MSG
