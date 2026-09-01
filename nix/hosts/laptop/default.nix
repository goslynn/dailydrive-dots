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

  i18n = {
    # UI language stays English. es_CL is the *secondary* language: it shows up
    # in LC_* below and as the second keyboard layout (conf.d/input.lua), not as
    # the app language.
    defaultLocale = "en_US.UTF-8";

    # glibc only builds the locales named here. The NixOS default is
    # [defaultLocale "C.UTF-8"] plus whatever extraLocaleSettings mentions, and
    # a locale that was never generated silently falls back to C — dates in
    # English, `locale -a` missing the entry, `LANG=es_CL.UTF-8 <app>` doing
    # nothing. Spelling the list out keeps es_ES available too, for anything
    # that only ships peninsular Spanish.
    supportedLocales = [
      "C.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
      "es_CL.UTF-8/UTF-8"
      "es_ES.UTF-8/UTF-8"
    ];

    # Regional formats follow time.timeZone above: 24h clock, dd-mm-yyyy, CLP,
    # metric, A4.
    #
    # LC_NUMERIC is deliberately NOT here. es_CL uses "," as the decimal
    # separator, and that leaks into anything that formats or parses numbers
    # through libc — awk, sort -n, printf "%f" in shell scripts, some CLI tools
    # — which breaks pipelines in ways that are painful to trace back to a
    # locale. Same reasoning for LC_COLLATE: sort order stays C/en_US.
    extraLocaleSettings = {
      LC_TIME = "es_CL.UTF-8";
      LC_MONETARY = "es_CL.UTF-8";
      LC_PAPER = "es_CL.UTF-8";
      LC_MEASUREMENT = "es_CL.UTF-8";
      LC_ADDRESS = "es_CL.UTF-8";
      LC_TELEPHONE = "es_CL.UTF-8";
      LC_NAME = "es_CL.UTF-8";
    };
  };

  # TTY only, and a console keymap is single-valued — there is no group switch
  # to bind down here. Stays "us"; the es layout is a Wayland-session thing
  # (conf.d/input.lua + SUPER + SHIFT + SPACE).
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
      "docker" # talk to /run/docker.sock without sudo; see nix/system/services.nix
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
