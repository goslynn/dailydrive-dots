# PLACEHOLDER — replaced during installation.
#
# The real file is machine-specific (filesystem UUIDs, swap, kernel modules for
# the actual disk controller) and is produced by `nixos-generate-config` on the
# target machine. `install.sh` copies it from /etc/nixos over this file before
# the first `nixos-rebuild switch`.
#
# It exists in git only so the flake evaluates (and `nixos-rebuild build-vm`
# works) on a machine that has not been installed yet. Booting bare metal from
# these values will NOT work — they describe no real disk.
{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usbhid"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-amd" ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
