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
    -- graphical-session.target — REQUIRED for the XDG portals to exist at all.
    --
    -- NixOS ships xdg-desktop-portal{,-gtk,-hyprland,-termfilechooser} as user
    -- units that are Wants= of graphical-session.target, and the main one adds
    --   Requisite=graphical-session.target
    -- so a D-Bus activation of org.freedesktop.portal.Desktop fails outright
    -- ("Dependency failed for Portal service") whenever that target is down.
    --
    -- Nothing brings it up here: greetd execs Hyprland directly, and this repo
    -- deliberately keeps noctalia off systemd (see nix/system/desktop.nix), so
    -- no session manager ever reaches the target. Result: zero portals, and
    -- Brave silently falls back to its *built-in* GTK file dialog — which is
    -- the "GTK/GNOME-looking" picker that showed up instead of yazi, and the
    -- reason xdg-misc/.config/xdg-desktop-portal/hyprland-portals.conf was
    -- being ignored.
    --
    -- graphical-session.target has RefuseManualStart=yes, so it cannot be
    -- started directly. nixos-fake-graphical-session.target is the escape
    -- hatch NixOS provides for exactly this case (non-systemd-aware sessions):
    -- it is BindsTo= the real target, so starting it pulls the target up and
    -- tearing it down takes the portals with it.
    --
    -- Hyprland already pushes WAYLAND_DISPLAY / XDG_CURRENT_DESKTOP /
    -- HYPRLAND_INSTANCE_SIGNATURE into the systemd user manager on its own
    -- (confirmed via `systemctl --user show-environment`), so no
    -- dbus-update-activation-environment call is needed alongside this.
    hl.exec_cmd("systemctl --user start nixos-fake-graphical-session.target")

    -- Shell: bar, notifications, launcher, clipboard, control center, OSDs,
    -- screenshots, lockscreen. Config lives in ~/.config/noctalia, not here.
    hl.exec_cmd("noctalia")

    -- Wallpaper: owned by noctalia (images via its built-in wallpaper picker,
    -- video via the mpvpaper plugin). Gallery at ~/Pictures/Wallpapers. No
    -- separate daemon needed.

    -- Clipboard history store, read by noctalia's clipboard panel (SUPER+C).
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
