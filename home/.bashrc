# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source "$OMARCHY_PATH/default/bash/rc"

# Show the zellij keybinding cheatsheet in the first pane of each new
# session (i.e. once per foot window, not for every tab/pane).
if [[ -n "$ZELLIJ" && "$ZELLIJ_PANE_ID" == "0" ]]; then
  printf '\e[2m┌ zellij ── Super = Hyprland, Alt = zellij ─────────────────────────┐\e[0m\n'
  printf '\e[2m│\e[0m \e[36mtabs \e[0m  Alt+Enter new   Alt+1..0 go to   Alt+, / Alt+. prev/next   \e[2m│\e[0m\n'
  printf '\e[2m│\e[0m        Alt+W close     Alt+R rename                               \e[2m│\e[0m\n'
  printf '\e[2m│\e[0m \e[36mpanes\e[0m  Alt+N new   Alt+arrows focus   Alt+F float   Alt+± resize  \e[2m│\e[0m\n'
  printf '\e[2m└───────────────────────────────────────────────────────────────────┘\e[0m\n'
fi

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'
