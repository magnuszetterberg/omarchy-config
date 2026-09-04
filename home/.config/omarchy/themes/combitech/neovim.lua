-- Combitech: tokyonight as the base, repainted with the brand palette
-- (#000814 deep navy ground, #0A5CC4 primary, #00E5A8 CTA teal).
return {
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    opts = {
      style = "night",
      on_colors = function(c)
        c.bg = "#000814"
        c.bg_dark = "#00040C"
        c.bg_dark1 = "#000206"
        c.bg_float = "#00040C"
        c.bg_sidebar = "#00040C"
        c.bg_statusline = "#00040C"
        c.bg_popup = "#00040C"
        c.bg_highlight = "#0A2A52"
        c.bg_visual = "#0A5CC4"
        c.bg_search = "#0A5CC4"
        c.border = "#0A2A52"
        c.border_highlight = "#00E5A8"

        c.fg = "#DCEBF7"
        c.fg_dark = "#C4DCF0"
        c.fg_float = "#DCEBF7"
        c.fg_sidebar = "#C4DCF0"
        c.fg_gutter = "#2C5C8F"
        c.comment = "#5A85B0"

        c.blue = "#1E90FF"
        c.blue0 = "#0A5CC4"
        c.blue1 = "#4DFFD0"
        c.blue2 = "#00E5A8"
        c.blue5 = "#5CB4FF"
        c.blue6 = "#C4DCF0"
        c.blue7 = "#0A2A52"
        c.cyan = "#00E5A8"
        c.teal = "#4DFFD0"
        c.green = "#7ED321"
        c.green1 = "#A8F03C"
        c.green2 = "#7ED321"
        c.yellow = "#FFB300"
        c.orange = "#FF7A1F"
        c.red = "#FF2D55"
        c.red1 = "#FF5C7A"
        c.magenta = "#B15CFF"
        c.magenta2 = "#CE94FF"
        c.purple = "#CE94FF"

        c.error = "#FF2D55"
        c.warning = "#FFB300"
        c.info = "#00E5A8"
        c.hint = "#5CB4FF"

        c.git = { add = "#7ED321", change = "#FFB300", delete = "#FF2D55" }
      end,
      on_highlights = function(hl, c)
        hl.CursorLineNr = { fg = c.cyan, bold = true }
        hl.LineNr = { fg = "#2C5C8F" }
        hl.Visual = { bg = "#0A5CC4" }
        hl.WinSeparator = { fg = "#0A2A52" }
        hl.FloatBorder = { fg = "#00E5A8", bg = c.bg_float }
        hl.TelescopeBorder = { fg = "#00E5A8", bg = c.bg_float }
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-night",
    },
  },
}
