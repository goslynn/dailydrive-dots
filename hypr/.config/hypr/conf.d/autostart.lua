-- Services launched once at Hyprland startup.
--
-- The hyprland.start event is the Lua replacement for `exec-once`. Like
-- exec-once, it does NOT fire on `hyprctl reload` — only on a real startup.
-- After adding an entry here, either restart the session or launch it by hand:
--   setsid -f <cmd> > /tmp/<cmd>.log 2>&1 &
--
-- Not started here any more, and why:
--   nm-applet     -> noctalia's control center owns network/wifi
--   polkit-gnome  -> noctalia ships its own polkit agent (NoctaliaPolkitListener)

hl.on("hyprland.start", function()
    -- Shell: bar, notifications, launcher, clipboard, control center, OSDs,
    -- screenshots, lockscreen. Config lives in ~/.config/noctalia, not here.
    hl.exec_cmd("noctalia")

    -- Wallpaper: waypaper-engine daemon (re-applies the last wallpaper from its
    -- gallery DB at ~/.config/waypaper-engine/). GUI picker: `waypaper-engine`.
    hl.exec_cmd("waypaper-daemon")

    -- Clipboard history store, read by noctalia's clipboard panel (SUPER+C).
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
