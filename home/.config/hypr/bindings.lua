-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Screenshot: select a region, annotate it in Tensaku.
-- Esc copies to the clipboard and closes the editor; Enter copies without closing.
-- (SUPER + SHIFT + S was previously bound to the Google Maps webapp.)
hl.unbind("SUPER + SHIFT + S")
o.bind(
  "SUPER + SHIFT + S",
  "Screenshot region and edit",
  [[bash -c 'f=$(omarchy capture screenshot region save) && [ -n "$f" ] && tensaku --filename "$f" --output-filename "$f" --initial-tool brush --disable-notifications --actions-on-enter save-to-clipboard --actions-on-escape save-to-clipboard,exit --save-after-copy --copy-command wl-copy']]
)

-- Show desktop (SUPER + D was unbound; SUPER+CTRL+D, SUPER+SHIFT+D and
-- SUPER+CTRL+ALT+D are untouched).
--
-- Hyprland has no minimise, so this stashes every window on the workspace each
-- monitor is currently showing into a special workspace, and pulls them back on
-- the next press. The origin workspace id is encoded in the special workspace's
-- name instead of a state file, so nothing can drift out of sync after a reload
-- or a crash.
local SHOW_DESKTOP_PREFIX = "special:sd_"

local function show_desktop_toggle()
  local restored = false

  for _, window in ipairs(hl.get_windows()) do
    local workspace = window.workspace
    if workspace and workspace.name:sub(1, #SHOW_DESKTOP_PREFIX) == SHOW_DESKTOP_PREFIX then
      hl.dispatch(hl.dsp.window.move({
        window = "address:" .. window.address,
        workspace = workspace.name:sub(#SHOW_DESKTOP_PREFIX + 1),
        follow = false,
      }))
      restored = true
    end
  end

  if restored then
    return
  end

  local visible = {}
  for _, monitor in ipairs(hl.get_monitors()) do
    if monitor.active_workspace then
      visible[monitor.active_workspace.id] = true
    end
  end

  for _, window in ipairs(hl.get_windows()) do
    local workspace = window.workspace
    if workspace and not workspace.special and visible[workspace.id] then
      hl.dispatch(hl.dsp.window.move({
        window = "address:" .. window.address,
        workspace = SHOW_DESKTOP_PREFIX .. workspace.id,
        follow = false,
      }))
    end
  end
end

o.bind("SUPER + D", "Show desktop", show_desktop_toggle)

-- Monitor scaling (SUPER + / and SUPER + ALT + /).
--
-- Same command as the Omarchy default, but the wrapper in
-- ~/.local/share/omarchy-overrides/bin (which re-reads monitors.lua, so the
-- whole desk is laid out again for the new scale rather than just the focused
-- screen being reflowed). Named by full path so it applies now: the overrides
-- directory only enters PATH at the next login, and the menu's own scale
-- entries pick the wrapper up then.
local monitor_scaling = os.getenv("HOME") .. "/.local/share/omarchy-overrides/bin/omarchy-hyprland-monitor-scaling"

hl.unbind("SUPER + SLASH")
hl.unbind("SUPER + ALT + SLASH")
o.bind("SUPER + SLASH", "Monitor scaling up", monitor_scaling .. " up")
o.bind("SUPER + ALT + SLASH", "Monitor scaling down", monitor_scaling .. " down")
