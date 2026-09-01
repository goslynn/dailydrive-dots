# gsettings/dconf — la mitad del theming que NO puede vivir en un dotfile.
#
# Todo lo demás de apariencia en este repo es un fichero enlazado desde
# ~/.dotfiles (ver ./dotfiles.nix). Esto no: dconf es una base de datos binaria
# en ~/.config/dconf/user, y es la única fuente que consulta
# xdg-desktop-portal-gtk para responder al portal Settings
# (org.freedesktop.impl.portal.Settings).
#
# Por qué importa ese portal: es como se enteran del modo oscuro las cosas que
# no leen ni GTK_THEME ni gtk-3.0/settings.ini —
#
#   Chromium / Electron  brave, obsidian, spotify, bruno
#   Qt 6                 lee org.freedesktop.appearance / color-scheme por
#                        D-Bus (comprobable con `strings` sobre libQt6Gui.so)
#   libadwaita / GTK4    ignora por completo los temas de GTK3
#
# Sin `color-scheme = prefer-dark` todas ellas asumen tema claro y aparecen
# ventanas blancas en medio de una sesión Catppuccin Frappé.
#
# Los valores tienen que coincidir con los paquetes de nix/system/desktop.nix y
# con gtk/.config/gtk-3.0/settings.ini.
#
# programs.dconf.enable está en nix/system/desktop.nix: sin el daemon, esto se
# escribiría pero nadie lo leería.
{ ... }:
{
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";

      gtk-theme = "catppuccin-frappe-lavender-standard";
      icon-theme = "Papirus-Dark";
      cursor-theme = "catppuccin-frappe-dark-cursors";
      cursor-size = 24;

      font-name = "Google Sans 11";
      document-font-name = "Google Sans 11";
      monospace-font-name = "CaskaydiaCove Nerd Font 11";
      font-antialiasing = "rgba";
      font-hinting = "slight";
    };
  };
}
