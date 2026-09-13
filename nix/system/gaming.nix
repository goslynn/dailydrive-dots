# Gaming: Steam, Proton, controller support, and the pieces non-Nix-packaged
# games/ports need to run at all on NixOS.
{ pkgs, ... }:
{
  # ── Steam ────────────────────────────────────────────
  # This one option pulls in Steam itself, steam-run (an FHS-compatible
  # sandbox — also independently useful for running non-Steam prebuilt
  # binaries, see steam-run below), and sets hardware.graphics.enable32Bit
  # for you. It's kept explicit below anyway since emulators outside Steam
  # (Dolphin, PCSX2, RetroArch cores) need it too and shouldn't silently
  # depend on Steam being enabled to get it.
  programs.steam = {
    enable = true;

    # Opens the firewall ports Steam Remote Play / in-home streaming and
    # the local network game-transfer feature need. Off by default upstream
    # because it's a firewall hole; this is a single-user laptop so the
    # trade is fine.
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;

    # Proton-GE via nixpkgs: shows up in Steam's per-game "Compatibility"
    # dropdown alongside stock Proton, reproducible and pinned by flake.lock.
    # This is the *floor* — always present even offline / before ProtonUp-Qt
    # has fetched anything. It typically trails the newest upstream GE
    # release by a bit, which is what protonup-qt below is for: fetching a
    # specific just-released build for one problem game without waiting on a
    # nixpkgs bump.
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

  # 32-bit OpenGL/Vulkan (RADV) for the 680M. Most Steam games and Proton
  # itself are still built 32-bit, and this is what a plain `wine`/emulator
  # invocation outside Steam needs too — kept explicit rather than relying on
  # programs.steam to imply it.
  hardware.graphics.enable32Bit = true;

  # ── Performance ──────────────────────────────────────
  # gamemoded bumps CPU governor/scheduling priority (and I/O priority) for
  # the duration of a game process, then reverts on exit. Games opt in via
  # `gamemoderun %command%` as a Steam launch option, or automatically if
  # they link libgamemode themselves. Matters more here than on a desktop:
  # this is a single shared power budget between CPU and iGPU.
  programs.gamemode.enable = true;

  # ── Controllers ──────────────────────────────────────
  # udev rules for Steam Controller, Steam Deck-style controllers, and
  # generic HID gamepads at the right permissions — independent of whether
  # Steam itself is what's reading them (RetroArch/Dolphin benefit too).
  hardware.steam-hardware.enable = true;

  # ── Arbitrary non-Nix binaries ───────────────────────
  # Ports like Ship of Harkinian, and most emulator AppImages/tarballs, ship
  # as plain dynamically-linked ELF binaries built against a standard FHS
  # distro (glibc at /lib64/ld-linux-x86-64.so.2, libs under /usr/lib). NixOS
  # has none of that by default, so double-clicking or `./soh` on such a
  # binary fails with "No such file or directory" even though the file is
  # right there — it's the *interpreter* that's missing, not the binary.
  #
  # nix-ld installs a real ELF interpreter at the path those binaries expect
  # and, via NIX_LD_LIBRARY_PATH below, hands it a library search path built
  # from Nix packages. This covers running such binaries directly; Steam
  # itself doesn't need this for its own games since programs.steam already
  # wraps things through steam-run's FHS sandbox.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # The common set unpackaged game binaries/ports reach for: OpenGL/GL
      # dispatch, X11 (even under Wayland, via XWayland), audio, and the
      # usual C++ runtime bits.
      libGL
      vulkan-loader
      xorg.libX11
      xorg.libXext
      xorg.libXrandr
      xorg.libXi
      xorg.libXcursor
      xorg.libXfixes
      libxkbcommon
      alsa-lib
      systemdLibs # libudev
      stdenv.cc.cc.lib # libstdc++
      zlib
      openssl
    ];
  };

  # ── Perf overlay ─────────────────────────────────────
  # MangoHud: on-screen FPS/frametime/CPU-GPU-temp overlay. Worth having on
  # an iGPU laptop specifically to see at a glance whether a game is
  # CPU-bound or iGPU-bound before reaching for a Proton/settings change.
  # Enable per-game with `mangohud %command%` (Steam launch options) or
  # `MANGOHUD=1 <cmd>` for anything launched from a terminal.
  environment.systemPackages = with pkgs; [
    mangohud
  ];
}
