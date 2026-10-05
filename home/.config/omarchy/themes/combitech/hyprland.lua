-- Combitech: the brand gradient, applied to the whole compositor rather than
-- just the border colour. Loaded from default/hypr/omarchy.lua after Omarchy's
-- defaults and before ~/.config/hypr/looknfeel.lua, so anything set here wins
-- over the defaults and stays overridable per-machine.

-- Three stops so the gradient reads as teal-navy-teal from any angle. The
-- same spec lives in colors.toml (hyprland_active_border), which is what the
-- shell's popup/menu/notification borders derive from -- keep them in sync.
local active_border_color = {
  colors = { "rgba(4DFFD0ff)", "rgba(0A5CC4ff)", "rgba(4DFFD0ff)" },
  angle = 45,
}
local inactive_border_color = "rgba(0A5CC455)"

hl.config({
  general = {
    border_size = 3,
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },

  decoration = {
    -- Soft corners so the teal border reads as a ring rather than a box.
    rounding = 8,
    rounding_power = 3,

    -- Teal bloom behind the focused window. This is the cheap half of the
    -- "spicy" look: it only paints around the active window.
    shadow = {
      enabled = true,
      range = 22,
      render_power = 3,
      color = "rgba(00E5A855)",
      color_inactive = "rgba(00020600)",
      offset = "0 2",
    },

    -- Blur is opt-in per layer below, not global: windows stay opaque, so
    -- the only surfaces that pay for it are the bar and the menus.
    blur = {
      enabled = true,
      size = 5,
      passes = 2,
      vibrancy = 0.25,
      brightness = 0.85,
      contrast = 1.1,
      noise = 0.015,
      new_optimizations = true,
      xray = true,
      popups = true,
    },

    -- Uncomment to darken unfocused windows as well.
    -- dim_inactive = true,
    -- dim_strength = 0.1,
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },

    groupbar = {
      gradients = true,
      gradient_rounding = 6,
      text_color = "rgb(00E5A8)",
      text_color_inactive = "rgba(5A85B0cc)",
      col = {
        active = "rgba(0A5CC466)",
        inactive = "rgba(00020640)",
      },
    },
  },
})

-- Frost the shell's own layers. Namespaces match default/hypr/apps/omarchy-shell.lua.
hl.layer_rule({ match = { namespace = "omarchy-bar" }, blur = true, ignore_alpha = 0.1 })
hl.layer_rule({
  match = { namespace = "^(omarchy-menu|omarchy-image-selector|omarchy-emojis|omarchy-clipboard|omarchy-keyboard-panel)$" },
  blur = true,
  ignore_alpha = 0.1,
})
hl.layer_rule({ match = { namespace = "^omarchy-notifications?$" }, blur = true, ignore_alpha = 0.1 })

-- Slowly sweep the gradient around the focused window. One revolution every
-- ~10s; set enabled = false here if the idle GPU wakeups ever matter.
hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "linear", style = "loop" })
