-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2

-- Wanted scale. This is a wish, not a command: Hyprland only accepts a scale
-- that divides a panel's pixel size into whole logical pixels, so the value
-- below is snapped to the nearest scale that every connected panel accepts
-- (see snap_scale). Set it to anything; nothing breaks.
--   home: 1 1.2 1.25 1.333 1.5 1.6 1.667 1.875 2 2.4 2.5 are exact
--   work: 1 1.25 1.333 1.6 1.667 2 2.5 are exact (the 3440px ultrawide is the
--         picky one -- it has no 1.2 and no 1.5)
-- Check what was actually applied with: hyprctl monitors | grep -E 'Monitor|scale'
local omarchy_monitor_scale = 1.6

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Catch-all for anything not in the desk layout below (projector, TV, ...).
-- Left on "auto" because an unknown panel may not accept the desk scale.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Desk order, left to right. The same laptop docks at two desks with different
-- panels, so positions are computed at config-load time from whatever is
-- actually plugged in: these monitors are placed edge to edge in this order and
-- missing ones are skipped rather than leaving a hole.
--
-- Identified by EDID serial, NOT by port. The port a monitor lands on is not
-- stable -- this laptop has two GPUs and the same three panels have already
-- moved from card2's DP-7/8/9 to card1's DP-2/3/4, and at work the Philips
-- and the Dell have swapped DP-7/DP-8 between docks, which silently broke
-- every port-based rule below. A serial is stamped into the panel and never
-- moves.
--
-- An entry may also be a connector name, for a panel that reports no serial
-- (the built-in eDP-1) or one whose serial has not been read yet.
-- Read the serials of what is plugged in right now with:
--   hyprctl monitors all | grep -E '^Monitor|serial:'
--   home: eDP-1 | CNC9292X78 HP E243 | H3CNL23 Dell P2421 | CW2NL23 Dell P2421
--   work: eDP-1 | UK02239009678 Philips 34B1U5600 (ultrawide) | GX71RP3 Dell P2422H
local layout_order = { "eDP-1", "UK02239009678", "CNC9292X78", "H3CNL23", "CW2NL23", "GX71RP3" }

-- Workspace pinned per monitor, so Super+N lands on the same physical screen at
-- both desks. A workspace whose monitor is absent falls back to the widest
-- screen that is connected, so no workspace is ever homeless.
local workspace_layout = {
  { "1", "eDP-1" },
  { "2", "eDP-1" },
  { "3", "eDP-1" },
  { "4", "CNC9292X78" },
  { "5", "H3CNL23" },
  { "6", "CW2NL23" },
}

local function read_first_line(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local line = file:read("*l")
  file:close()

  return line
end

local function read_binary(path)
  local file = io.open(path, "rb")
  if not file then
    return nil
  end

  local blob = file:read("*a")
  file:close()

  return blob
end

-- Pull the serial out of a raw EDID block. The four 18-byte descriptors start
-- at offset 54; the one tagged 0xFF (after a 00 00 00 header, which is what
-- distinguishes a text descriptor from a detailed timing) holds the serial as
-- text, cut short by a newline and right-padded with spaces.
-- This is the same string Hyprland reports as "serial:" and tacks onto the end
-- of a monitor's description.
local function edid_serial(blob)
  if not blob or #blob < 128 then
    return nil
  end

  for _, base in ipairs({ 54, 72, 90, 108 }) do
    local descriptor = blob:sub(base + 1, base + 18)
    if #descriptor == 18
      and descriptor:byte(1) == 0
      and descriptor:byte(2) == 0
      and descriptor:byte(3) == 0
      and descriptor:byte(4) == 0xFF
    then
      local text = descriptor:sub(6, 18):gsub("\n.*", ""):gsub("%s+$", "")
      if text ~= "" then
        return text
      end
    end
  end

  return nil
end

-- Every connected DRM connector, keyed by BOTH its EDID serial and the name
-- Hyprland uses for the port (the kernel's "cardN-" prefix stripped), so a
-- layout entry can be either:
--   { ["H3CNL23"] = { output = "DP-4", width = 1920, height = 1200 },
--     ["DP-4"]    = { output = "DP-4", width = 1920, height = 1200 } }
-- The first line of a connector's "modes" is its preferred mode.
local function connected_panels()
  local panels = {}

  local pipe = io.popen("ls /sys/class/drm 2>/dev/null")
  if not pipe then
    return panels
  end

  local entries = {}
  for entry in pipe:lines() do
    table.insert(entries, entry)
  end
  pipe:close()

  for _, entry in ipairs(entries) do
    local output = entry:match("^card%d+%-(.+)$")
    if output and read_first_line("/sys/class/drm/" .. entry .. "/status") == "connected" then
      local mode = read_first_line("/sys/class/drm/" .. entry .. "/modes")
      if mode then
        -- Parenthesised so the two captures survive; `x and x:match(...)`
        -- would silently drop the height.
        local width, height = mode:match("^(%d+)x(%d+)")
        if width then
          local panel = { output = output, width = tonumber(width), height = tonumber(height) }
          panels[output] = panel

          local serial = edid_serial(read_binary("/sys/class/drm/" .. entry .. "/edid"))
          if serial then
            panels[serial] = panel
          end
        end
      end
    end
  end

  return panels
end

-- Hyprland stores scale in 1/120ths and demands that a panel's pixel size come
-- out as whole logical pixels: with the scale written as n/120, both
-- width * 120 / n and height * 120 / n have to be integers. A scale that fails
-- this is rejected with an "invalid scale" notification and that monitor drops
-- back to something else -- which is also why placement fell apart, since the
-- offsets below are measured in logical pixels and were computed from a scale
-- the monitor never actually got.
--
-- So: pick the scale nearest the wish above that EVERY listed panel accepts.
-- One shared scale rather than one per panel, so windows are the same physical
-- size on every screen. n = 120 (scale 1) always works, so this always answers.
local function snap_scale(panels, wanted)
  local function divides_all(n)
    if n < 1 then
      return false
    end

    for _, panel in ipairs(panels) do
      if (panel.width * 120) % n ~= 0 or (panel.height * 120) % n ~= 0 then
        return false
      end
    end

    return #panels > 0
  end

  local target = math.floor(wanted * 120 + 0.5)
  if divides_all(target) then
    return target
  end

  -- Walk outwards in 1/120 steps, preferring the lower scale on a tie.
  for step = 1, 240 do
    if divides_all(target - step) then
      return target - step
    end
    if divides_all(target + step) then
      return target + step
    end
  end

  return 120
end

-- Lay the connected monitors out edge to edge, top-aligned. If nothing could be
-- detected, no explicit monitor lines are emitted and the catch-all above
-- handles placement with "auto".
local detected = connected_panels()
local desk = {}
local placed = {}

for _, id in ipairs(layout_order) do
  local panel = detected[id]
  -- A panel listed twice (say, once by serial and once by its port) is placed
  -- once, at its first mention.
  if panel and not placed[panel.output] then
    placed[panel.output] = true
    table.insert(desk, { id = id, panel = panel })
  end
end

local ordered_panels = {}
for _, entry in ipairs(desk) do
  table.insert(ordered_panels, entry.panel)
end

local scale_units = snap_scale(ordered_panels, omarchy_monitor_scale)
local scale = string.format("%.6f", scale_units / 120)

local offset = 0
local outputs = {}
local widest, widest_width = nil, 0

for _, entry in ipairs(desk) do
  local panel = entry.panel

  hl.monitor({
    output = panel.output,
    mode = "preferred",
    position = string.format("%dx0", offset),
    scale = scale,
  })

  -- Keyed by the id the layout used, which is what workspace_layout names.
  outputs[entry.id] = panel.output
  if panel.width > widest_width then
    widest, widest_width = panel.output, panel.width
  end

  -- Logical width, which is what the next monitor's position is measured in.
  -- Exact by construction: scale_units was chosen to divide this cleanly.
  offset = offset + (panel.width * 120) // scale_units
end

for _, rule in ipairs(workspace_layout) do
  local workspace, output = rule[1], outputs[rule[2]] or widest

  if output then
    hl.workspace_rule({ workspace = workspace, monitor = output })
  end
end
