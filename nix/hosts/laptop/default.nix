# Host: laptop — AMD Rembrandt (Ryzen + Radeon 680M iGPU), UEFI, single user.
#
# hardware-configuration.nix is NOT in git: it describes the disks of one
# specific install (filesystem UUIDs, swap, LUKS). `install.sh` copies the one
# `nixos-generate-config` produced into this directory before the first build.
{ pkgs, lib, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # ── Boot ─────────────────────────────────────────────
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # ── Identity ─────────────────────────────────────────
  networking.hostName = "vgonz-nix";
  time.timeZone = "America/Santiago";

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  # ── User ─────────────────────────────────────────────
  # No initialPassword here: it would end up world-readable in the Nix store.
  # install.sh prompts for it with `passwd` after the first switch.
  users.users.vgonz = {
    isNormalUser = true;
    description = "vgonz";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
    ];
  };

  # ── Hardware ─────────────────────────────────────────
  hardware.cpu.amd.updateMicrocode = true;
  hardware.graphics.enable = true; # Mesa/RADV for the 680M

  # ── Nix ──────────────────────────────────────────────
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  # Rolling channel, so keep the store from growing without bound.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nixpkgs.config.allowUnfree = true;

  # The release this config was first written against. Do NOT bump it on
  # upgrade — it pins stateful defaults (database versions and the like), not
  # package versions.
  system.stateVersion = lib.mkDefault "25.11";
}
