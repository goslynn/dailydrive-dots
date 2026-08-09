# Login screen — greetd + noctalia-greeter (replaces SDDM from the Arch setup).
#
# How it fits together: greetd runs `noctalia-greeter-session`, which brings up
# a small wlroots compositor (noctalia-greeter-compositor) and runs the greeter
# client inside it. The module (from the noctalia-greeter flake, imported in
# flake.nix) enables greetd, points its default session at that wrapper, and
# turns on accounts-daemon for user avatars — all with mkDefault.
{ pkgs, ... }:
{
  programs.noctalia-greeter = {
    enable = true;

    # The module comes from the flake's main branch; the binary comes from
    # nixpkgs (v1.1.0) so a fresh install pulls it from the binary cache
    # instead of compiling wlroots and a C++ tree. The module only needs
    # ${package}/bin/noctalia-greeter-session, which v1.1.0 exposes as its
    # mainProgram. If the two ever drift, drop this line and let the flake
    # build its own.
    package = pkgs.noctalia-greeter;

    # Writes /var/lib/noctalia-greeter/greeter.toml.
    #
    # IMPORTANT — no [appearance.palette] and no [appearance.wallpaper] here.
    # Keys in greeter.toml WIN over the sync.toml that noctalia produces, so
    # declaring the palette would freeze the greeter's look and cut the shell
    # out of it. Colors and wallpaper are pushed from noctalia instead, via
    # Settings -> Security -> Noctalia Greeter -> Sync Now.
    #
    # What belongs here is only what the shell does not own: which session,
    # which user, and the input/cursor bits that must match the session.
    settings = {
      # Label as printed by `noctalia-greeter sessions`, not the .desktop id.
      session.default = "Hyprland";
      user.default = "vgonz";

      # Mirrors conf.d/env.lua
      cursor = {
        theme = "catppuccin-mocha-dark-cursors";
        size = 24;
        path = "${pkgs.catppuccin-cursors.mochaDark}/share/icons";
      };

      # Mirrors conf.d/input.lua
      keyboard.layout = "us";

      # Take colors from whatever noctalia last synced.
      appearance.scheme = "Synced";
    };
  };

  # No [output].name: the greeter mirrors onto every connected output, which is
  # what we want here. conf.d/monitors.lua disables eDP-1 whenever the external
  # is plugged in, so in practice only one panel is ever live.
}
