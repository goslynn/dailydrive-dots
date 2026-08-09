# System-wide packages.
#
# The rule of thumb: this list is for things that must exist outside a user
# session — referenced by the greeter, by a portal, by a systemd unit, or
# needed to repair a broken home-manager generation. Everything that is just
# "a tool vgonz uses" belongs in nix/home/packages.nix instead.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Bootstrap / recovery: install.sh needs these before home-manager has
    # ever run, and they must survive a broken user generation.
    git
    curl
    wget
    stow # not used to deploy, but keeps the Arch-era workflow available

    # kitty is spawned by the portal file chooser (TERMCMD in the
    # termfilechooser config), which runs outside the user session's PATH.
    kitty

    # Clipboard watchers started from conf.d/autostart.lua.
    wl-clipboard
    cliphist

    # Referenced by noctalia: mpvpaper plugin for video wallpapers, satty as
    # the external screenshot annotation editor.
    mpv
    mpvpaper
    satty

    udisks2
  ];
}
