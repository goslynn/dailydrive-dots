-- Environment variables exposed to all spawned processes

-- ── Cursor ───────────────────────────────────────────
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "catppuccin-frappe-dark-cursors")
hl.env("HYPRCURSOR_THEME", "catppuccin-frappe-dark-cursors")

-- ── Identidad de la sesión ───────────────────────────
--
-- No añadir un segundo escritorio aquí (p. ej. "Hyprland:GNOME"). Es un truco
-- conocido para que Qt elija el tema gtk3 solo, pero además cambia qué
-- <desktop>-portals.conf lee xdg-desktop-portal y hace aparecer entradas
-- OnlyShowIn=GNOME en el lanzador. El theming de Qt se resuelve abajo con
-- QT_QPA_PLATFORMTHEME, que no tiene esos efectos colaterales.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- ── Qt ───────────────────────────────────────────────
--
-- qt6ct como platform theme. La configuración real está en
-- qt/.config/qt6ct/qt6ct.conf (estilo Kvantum, paleta Catppuccin, iconos
-- Papirus y — lo importante — standard_dialogs=xdgdesktopportal, que manda los
-- QFileDialog al portal y por tanto a yazi).
--
-- Para que esto funcione hacen falta dos cosas más, ambas en
-- nix/system/desktop.nix: el paquete qt6ct y `qt.enable = true`, que es lo que
-- pone QT_PLUGIN_PATH apuntando a los perfiles. Sin eso, las apps Qt de nixpkgs
-- solo miran el QT_PLUGIN_PATH que les inyecta su propio wrapper y no
-- encuentran ni el platform theme ni el estilo.
--
-- Nota: el plugin de qt6ct registra también la clave "qt5ct", así que el día
-- que entre una app Qt5 basta con añadir libsForQt5.qt5ct y cambiar este valor
-- a "qt5ct" para que cada versión coja su propia herramienta.
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- Wayland nativo cuando se puede, XWayland cuando no. Sin esto Qt decide solo
-- y basta con que a una app le falte el plugin de wayland para que caiga a xcb
-- sin avisar.
hl.env("QT_QPA_PLATFORM", "wayland;xcb")

-- Sin decoraciones cliente de Qt: bajo un tiling las dibuja el compositor.
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-- NO fijar QT_STYLE_OVERRIDE: cortocircuita el proxy de qt6ct y deja el estilo
-- fuera de qt6ct.conf. El estilo se elige ahí con `style=kvantum`.

-- ── GTK ──────────────────────────────────────────────
--
-- Sin sufijo "+default", a diferencia de la rama de Arch: nixpkgs parchea
-- catppuccin-gtk (fix-inconsistent-theme-name.patch) para que el directorio del
-- tema no lleve el sufijo cuando no se pide ningún tweak. El nombre real lo
-- confirma `ls /run/current-system/sw/share/themes`.
hl.env("GTK_THEME", "catppuccin-frappe-lavender-standard")

-- File chooser de GTK3 por el portal → yazi.
--
-- GTK3 solo usa el portal si gtk_should_use_portal() dice que sí, y fuera de un
-- flatpak eso depende exclusivamente de esta variable. Sin ella, un
-- GtkFileChooserNative abre el diálogo GTK local y el portal ni se entera.
-- Afecta también a los diálogos de impresión y de "abrir con", que igualmente
-- los sirve xdg-desktop-portal-gtk.
hl.env("GTK_USE_PORTAL", "1")

-- GTK4 ya no lee GTK_USE_PORTAL: la decisión es gdk_display_should_use_portal()
-- (gdk/gdk.c), que fuera de un sandbox pregunta a D-Bus si el portal está
-- activable y además comprueba la versión mínima de la interfaz. Eso ya daría
-- que sí aquí; esta clave de GDK_DEBUG ("portals" fuerza, "no-portals"
-- desactiva) es la única palanca externa que lo hace determinista y se salta
-- esas dos comprobaciones.
--
-- No hay ninguna app GTK4 instalada hoy: esto es para que la primera que entre
-- no se lleve su propio file chooser. glib ignora en silencio las claves de
-- debug que no conoce, así que GTK3 no se queja de verla.
hl.env("GDK_DEBUG", "portals")

-- ── Chromium / Electron ──────────────────────────────
--
-- Los wrappers de nixpkgs (obsidian, spotify, bruno…) miran NIXOS_OZONE_WL y
-- solo entonces añaden --ozone-platform-hint=auto. Sin esto todos arrancan bajo
-- XWayland: texto borroso con el escalado fraccional de este portátil y el
-- file chooser de Chromium por la ruta X11 en vez del portal.
--
-- brave-origin no lo necesita (nix/home/packages.nix ya le pasa sus flags), y
-- ELECTRON_OZONE_PLATFORM_HINT cubre las apps Electron que no vienen envueltas
-- por nixpkgs; "auto" cae a X11 solo si Wayland no está disponible.
hl.env("NIXOS_OZONE_WL", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- ── XWayland ─────────────────────────────────────────
--
-- Java/AWT asume un WM reparenting. Bajo Hyprland (que no lo es) las ventanas
-- Swing salen en gris y sin repintarse hasta que se les fuerza este modo. Toca
-- a cualquier cosa sobre el JDK que hay en nix/home/packages.nix — IntelliJ
-- incluido, que además es quien registra x-scheme-handler/jetbrains en
-- mimeapps.list.
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

-- El DPI de las apps X11 no se puede fijar por variable de entorno sin romper
-- las nativas: se hace por recurso X (Xft.dpi) en conf.d/xwayland.lua.
