-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Bitwarden in Firefox. Omarchy's defaults only cover the desktop app and the
-- Chromium extension (default/hypr/apps/bitwarden.lua), so cover Firefox's
-- popped-out extension window here. Titles are anchored so an ordinary tab
-- about Bitwarden doesn't float the whole browser.
o.window({
  class = "^(firefox)$",
  title = "^(Bitwarden|Bitwarden — Mozilla Firefox|Extension: \\(Bitwarden Password Manager\\).*)$",
}, {
  no_screen_share = true,
  tag = "+floating-window",
})

-- Godot: float everything an F5 run puts on screen, keep the editor tiled.
-- An embedded run maps three windows, and rules are matched at map time, so
-- these match what is true then (not the final title):
--   editor       class "Godot"       maps titled "Godot"
--   game host    class "Godot"       maps titled "<Project> (DEBUG)"
--   game process class "<Project>"   maps titled "Godot"
-- The host is the window carrying the pause / audio-mute toolbar; the game
-- process window is overlaid inside it and must float too, or the tiler
-- fights Godot over its position. The editor matches neither rule.
-- Note: Hyprland matches these regexes in full, so "^.*" is required -- a
-- pattern anchored only at the end never matches.
o.window({ class = "^Godot$", initial_title = "^.*\\(DEBUG\\)$" }, { float = true, center = true })
o.window({ class = "negative:^Godot$", initial_title = "^Godot$" }, { float = true })

-- Never idle-lock or start the screensaver while a browser or media player is
-- fullscreen, so watching Netflix isn't interrupted. The omarchy idle service
-- runs its IdleMonitor with respectInhibitors, so this suppresses the
-- screensaver and the lock together.
--
-- Matched by class, not by Omarchy's browser tags: apps/browser.lua strips the
-- chromium-based-browser tag off the YouTube and Zoom web apps, which are the
-- very windows this needs to cover. Note Hyprland matches these regexes in
-- full, so each alternative spells out the whole class.
--
-- "chrome-.*" is the class chromium gives a --app= window, which is how
-- omarchy-launch-webapp starts every web app (YouTube, Zoom, ...).
o.window(
  "([fF]irefox|zen|librewolf|(google-)?[cC]hrom(e|ium)|chrome-.*|[bB]rave-browser|[mM]icrosoft-edge|Vivaldi-stable|helium)",
  { idle_inhibit = "fullscreen" }
)
o.window(
  "(mpv|vlc|smplayer|Clapper|io\\.github\\.celluloid_player\\.Celluloid|org\\.kde\\.haruna|com\\.github\\.rafostar\\.Clapper)",
  { idle_inhibit = "fullscreen" }
)

-- Files (Nautilus): always float. Omarchy's default only floats Nautilus when
-- it maps as a file-picker dialog (default/hypr/apps/system.lua); this covers
-- the ordinary browser window too. Anchored because Hyprland matches window
-- rule regexes in full.
o.window("^org\\.gnome\\.Nautilus$", { float = true })
