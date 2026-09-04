local active_border_color = {
  colors = { "rgba(00E5A8ff)", "rgba(0A5CC4ff)", "rgba(00E5A8ff)" },
  angle = 45,
}
local inactive_border_color = "rgba(0A2A5288)"

hl.config({
  general = {
    border_size = 3,
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },
})
