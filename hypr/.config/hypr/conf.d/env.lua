-- Environment variables exposed to all spawned processes

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "catppuccin-mocha-dark-cursors")
hl.env("HYPRCURSOR_THEME", "catppuccin-mocha-dark-cursors")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Sin qt5ct/qt6ct: las apps Qt siguen al tema GTK vía libqgtk3.so,
-- presente tanto en los plugins de Qt5 como en los de Qt6.
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")

-- Sin sufijo "+default", a diferencia de la rama de Arch: nixpkgs parchea
-- catppuccin-gtk (fix-inconsistent-theme-name.patch) para que el directorio del
-- tema no lleve el sufijo cuando no se pide ningún tweak. El nombre real lo
-- confirma `ls /run/current-system/sw/share/themes`.
hl.env("GTK_THEME", "catppuccin-mocha-blue-standard")
