{ ... }:
{
  imports = [
    ./dotfiles.nix
    ./packages.nix
  ];

  home = {
    username = "vgonz";
    homeDirectory = "/home/vgonz";

    # Same rule as system.stateVersion: pins stateful defaults, not versions.
    # Do not bump on upgrade.
    stateVersion = "25.11";
  };

  xdg.enable = true;

  programs.home-manager.enable = true;
}
