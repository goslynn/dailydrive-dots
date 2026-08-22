# Dotfile deployment — the Nix equivalent of the stow flow on master.
#
# Why mkOutOfStoreSymlink instead of letting Nix own the file contents:
# noctalia writes into these paths at runtime. Its enabled templates (btop,
# hyprland, kitty, starship, yazi — see noctalia/.config/noctalia/config.toml)
# regenerate
#
#   ~/.config/kitty/themes/noctalia.conf
#   ~/.config/btop/themes/noctalia.theme
#   ~/.config/yazi/flavors/noctalia.yazi/
#   ~/.config/hypr/noctalia.lua
#   the [palettes.noctalia] region *inside* ~/.config/starship.toml
#
# and btop rewrites its own btop.conf (save_config_on_exit = true). A read-only
# /nix/store symlink makes every one of those writes fail.
#
# mkOutOfStoreSymlink points at the working tree instead, so the targets stay
# writable, noctalia's generated themes land inside the repo, and `git status`
# keeps showing theme drift — the same behaviour documented in CLAUDE.md §3.
# The trade-off is that ~/.dotfiles must exist for the session to be complete;
# install.sh clones it before the first switch.
{ config, ... }:
let
  dots = "${config.home.homeDirectory}/.dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dots}/${path}";
in
{
  # yazi's own .desktop entry (from the yazi package) declares Terminal=true
  # and Exec=yazi %f, expecting the launcher to wrap it in a terminal. Under
  # Hyprland there's no xdg-terminal-exec set up, and NixOS's xdg-open
  # (xdg-utils) doesn't even read the Terminal= key at all — it just execs
  # `yazi <path>` with no TTY attached, so "open containing folder" from
  # Brave silently does nothing. hiPrio here overrides the package's
  # yazi.desktop with one that embeds the terminal directly in Exec, the same
  # way conf.d/programs.lua's file_manager = "kitty -e yazi" already does for
  # the in-Hyprland keybind.
  xdg.desktopEntries.yazi = {
    name = "Yazi File Manager";
    comment = "Blazing fast terminal file manager written in Rust, based on async I/O";
    icon = "yazi";
    exec = "kitty -e yazi %f";
    terminal = false;
    mimeType = [ "inode/directory" ];
    categories = [ "System" "FileManager" "FileTools" "ConsoleOnly" ];
  };

  xdg.configFile = {
    # hypr is deliberately NOT folded into a single directory symlink:
    # ~/.config/hypr has to be a real directory so noctalia can create
    # noctalia.lua next to our files. This mirrors the Arch layout, where stow
    # folded conf.d/ and hyprland.lua individually for the same reason.
    "hypr/hyprland.lua".source = link "hypr/.config/hypr/hyprland.lua";
    "hypr/conf.d".source = link "hypr/.config/hypr/conf.d";

    # These fold at directory level, exactly as stow did. noctalia writes into
    # kitty/themes/, btop/themes/ and yazi/flavors/ through the symlink, so the
    # generated files land in the repo.
    "kitty".source = link "kitty/.config/kitty";
    "btop".source = link "btop/.config/btop";
    "yazi".source = link "yazi/.config/yazi";
    "zsh".source = link "zsh/.config/zsh";
    "git".source = link "git/.config/git";
    "mpv".source = link "mpv/.config/mpv";
    "sioyek".source = link "sioyek/.config/sioyek";

    # Single files.
    "starship.toml".source = link "starship/.config/starship.toml";
    "mimeapps.list".source = link "xdg-misc/.config/mimeapps.list";
    "brave-origin-flags.conf".source =
      link "brave-origin/.config/brave-origin-flags.conf";

    # Portal wiring: which backend answers the file chooser, and how
    # termfilechooser launches kitty+yazi.
    "xdg-desktop-portal".source = link "xdg-misc/.config/xdg-desktop-portal";
    "xdg-desktop-portal-termfilechooser".source =
      link "xdg-misc/.config/xdg-desktop-portal-termfilechooser";

    # noctalia/ is NOT linked, on purpose. Its live config is layered:
    # ~/.config/noctalia/*.toml underneath, and ~/.local/state/noctalia/
    # settings.toml (written by the GUI) on top. The state layer always wins,
    # so a symlink here would be shadowed rather than respected — it would go
    # stale in silence. The repo keeps a one-way export instead
    # (scripts/.local/bin/noctalia-backup), and install.sh copies it in once.
    # See CLAUDE.md §1.
  };

  # ~/.local/bin — noctalia-backup. It resolves the repo with
  # `readlink -f "$0"`, which still lands in ~/.dotfiles through this symlink,
  # so the script works unchanged.
  home.file.".local/bin".source = link "scripts/.local/bin";
}
