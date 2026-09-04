# omarchy-config

My Omarchy (Arch + Hyprland) customisations, kept so a fresh install can be
brought back to the same state quickly.

## Restore on a fresh Omarchy install

```sh
git clone git@github.com:magnuszetterberg/omarchy-config.git ~/omarchy-config
~/omarchy-config/install-config.sh
```

That installs the needed packages, copies the home-directory files, asks for
sudo once to install the root-owned files, and activates the Combitech theme.
The two halves can also be run separately with `bin/install.sh --home` and
`sudo bin/install.sh --system`.

Log out and back in once afterwards so the override PATH from
`~/.config/uwsm/env.d` takes effect. Existing files are backed up next to
themselves as `<name>.bak.<timestamp>`.

## Save changes made on the live system

```sh
~/omarchy-config/sync-config.sh          # snapshot + commit + push
~/omarchy-config/sync-config.sh --check  # just show what changed
```

The same script runs every week from the `omarchy-config-sync.timer` user
unit (`systemctl --user list-timers` shows the next run). It also warns about
customised files that are not in `manifest` yet; add a `home/<path>` line
there to start tracking one. `bin/snapshot.sh` is the copy-only half if you
want to review before committing.

## What is in here

| Area | Files | What it does |
|---|---|---|
| Monitors | `.config/hypr/monitors.lua` | Matches external displays by EDID serial instead of DP port, packs them edge to edge, snaps the scale to values every panel accepts. Home and work desks both covered. |
| Hyprland | `.config/hypr/{bindings,hyprland,input}.lua` | Keybindings, window rules, input tweaks. |
| Bar and shell | `.config/omarchy/shell.json` | Bar layout, idle and lock timings. |
| Power panel | `.config/omarchy/plugins/magnus.power/` | Clone of the battery panel with a fourth profile, "Are u nuts?", that raises the CPU power caps on the 200 W barrel adapter. Shows "Plug in 200W charger" while waiting for it. |
| Menu | `.config/omarchy/plugins/magnus.menu/` | Clone of the Omarchy menu that shows keybinding hints next to apps and lists the extra power profile. |
| Media idle inhibit | `.config/omarchy/plugins/magnus.media-idle-inhibit/` | Blocks the screensaver while an MPRIS player is playing. |
| Command overrides | `.local/share/omarchy-overrides/bin/`, `.config/uwsm/env.d/50-omarchy-overrides` | Local replacements for packaged commands: calmer screensaver, monitor-scaling wrapper that re-reads monitors.lua, launcher keybinding hints, and the power-profile wrappers behind "Are u nuts?". |
| Terminal | `.config/foot/foot.ini`, `.config/zellij/config.kdl`, `.bashrc` | foot opens into zellij; Alt drives zellij the way Super drives Hyprland; cheatsheet printed in the first pane. |
| Theme | `.config/omarchy/themes/combitech/` | Custom theme. |
| CPU power caps | `system/usr/local/bin/zbook-power-caps` + systemd unit, udev rule, sudoers rule | HP ZBook Studio G9 firmware leaves the CPU peak cap at 45 W even on the 200 W adapter. This script raises it in "nuts" mode, re-applies on boot, resume and adapter events, and the sudoers rule lets the shell toggle it without a password. |

## Notes

- `magnus.power/Panel.qml` and `magnus.menu/Menu.qml` call the override
  scripts by absolute path under `/home/magnus`, because the running shell
  resolves `/usr/share/omarchy/bin` before the override directory. Adjust if
  the username changes.
- The sudoers rule is written for user `magnus`.
- Monitor serials for both desks are listed in `monitors.lua`; add a new
  panel by appending its serial to `layout_order`.
