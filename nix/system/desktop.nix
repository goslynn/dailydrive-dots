# Desktop: Hyprland compositor, noctalia shell, portals, fonts, themes, zsh.
# The login screen lives in ./greeter.nix.
{ pkgs, ... }:
{
  # ── Compositor ───────────────────────────────────────
  # The Lua config itself is not managed here — it is symlinked out of
  # ~/.dotfiles by home-manager (see nix/home/dotfiles.nix), exactly as stow
  # did on Arch.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true; # conf.d/xwayland.lua sets force_zero_scaling
  };

  # NixOS only links a short allowlist of /share subdirs into
  # /run/current-system/sw. Two things here need paths outside that list:
  #
  #   wayland-sessions  the greeter enumerates sessions from
  #                     /run/current-system/sw/share/wayland-sessions; greetd
  #                     starts with an empty environment, so XDG_DATA_DIRS
  #                     (which services.displayManager would set) is no help.
  #                     Without this the greeter offers no session to log into.
  #   …termfilechooser  holds yazi-wrapper.sh, referenced by absolute path from
  #                     xdg-misc/.config/xdg-desktop-portal-termfilechooser/config
  #
  # /share/hypr is already added by programs.hyprland, which is what puts the
  # Lua API stubs at /run/current-system/sw/share/hypr/stubs/hl.meta.lua.
  environment.pathsToLink = [
    "/share/wayland-sessions"
    "/share/xdg-desktop-portal-termfilechooser"
  ];

  # ── Portals ──────────────────────────────────────────
  # programs.hyprland already enables xdg.portal with its own portal; these are
  # the extras. Which backend handles the file chooser is decided by the user
  # config in xdg-misc/.config/xdg-desktop-portal/hyprland-portals.conf.
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-gtk
    xdg-desktop-portal-termfilechooser
  ];

  # ── Shell (noctalia) ─────────────────────────────────
  # systemd.enable stays off on purpose: conf.d/autostart.lua launches noctalia
  # from hl.on("hyprland.start", ...), and that stays the single owner of its
  # lifecycle, same as on Arch.
  #
  # recommendedServices pulls in NetworkManager, bluetooth, upower and a power
  # profile daemon with mkDefault — the integrations noctalia's control center
  # expects. See nix/system/services.nix for the rest.
  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
  };

  # ── Fonts ────────────────────────────────────────────
  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-cove # kitty.conf: CaskaydiaCove Nerd Font
    noto-fonts
    noto-fonts-color-emoji
    (callPackage ../pkgs/google-sans.nix { }) # noctalia config.toml font_family
  ];

  # ── Themes ───────────────────────────────────────────
  # Names must match what conf.d/env.lua exports.
  #
  #   catppuccin-cursors.mochaDark -> share/icons/catppuccin-mocha-dark-cursors
  #   catppuccin-gtk               -> share/themes/catppuccin-mocha-blue-standard
  #
  # Note the GTK theme has NO "+default" suffix here, unlike the AUR build:
  # nixpkgs carries fix-inconsistent-theme-name.patch, which drops it. env.lua
  # on this branch is set accordingly.
  environment.systemPackages = with pkgs; [
    catppuccin-cursors.mochaDark
    (catppuccin-gtk.override {
      variant = "mocha";
      accents = [ "blue" ];
      size = "standard";
    })
  ];

  # ── Shell ────────────────────────────────────────────
  programs.zsh = {
    enable = true;

    # Replaces the hand-installed /etc/zsh/zshenv from the Arch setup
    # (zsh/etc/zsh/zshenv in this repo). shellInit lands in /etc/zshenv, which
    # zsh reads before anything under $ZDOTDIR.
    shellInit = ''
      if [[ -z "$XDG_CONFIG_HOME" ]]; then
        export XDG_CONFIG_HOME="$HOME/.config"
      fi

      if [[ -d "$XDG_CONFIG_HOME/zsh" ]]; then
        export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
      fi
    '';

    # Keep the fpath wiring and nix-zsh-completions, but let our own .zshrc run
    # compinit — it uses a custom dump path under $XDG_CACHE_HOME.
    enableCompletion = true;
    enableGlobalCompInit = false;

    # starship owns the prompt (zsh/prompt.zsh).
    promptInit = "";
  };
}
