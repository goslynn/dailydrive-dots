{
  description = "vgonz — Hyprland + noctalia on NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # noctalia itself comes from nixpkgs. The greeter does not: its package is
    # in nixpkgs but its NixOS module only exists in this flake, so we need the
    # input for `programs.noctalia-greeter`. See nix/system/greeter.nix.
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      noctalia-greeter,
      ...
    }@inputs:
    {
      nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
        # No `system` argument on purpose. It is a legacy alias for
        # nixpkgs.hostPlatform, which hardware-configuration.nix already sets —
        # and defining both trips the nixpkgs assertion against mixing the
        # platform options with the legacy ones.
        specialArgs = { inherit inputs; };

        modules = [
          ./nix/hosts/laptop
          ./nix/system/desktop.nix
          ./nix/system/greeter.nix
          ./nix/system/services.nix
          ./nix/system/packages.nix

          noctalia-greeter.nixosModules.default

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.vgonz = import ./nix/home;

              # First switch runs against a home that already has files in it
              # (the installer copies noctalia's config, for one). Move them
              # aside instead of aborting the whole activation.
              backupFileExtension = "hm-bak";
            };
          }
        ];
      };
    };
}
