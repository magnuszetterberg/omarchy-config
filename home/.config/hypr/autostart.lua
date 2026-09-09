-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Re-read monitors.lua when a monitor is plugged in or out. That file computes
-- the whole desk layout (order, scale, positions) from the EDID serials of
-- whatever is connected, but Hyprland runs it only at config-load time -- so
-- without this, monitors that appear after startup (docking) are laid out by
-- the catch-all rule instead. See the script for the details.
o.launch_on_start("omarchy-monitor-hotplug")
