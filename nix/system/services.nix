# System services.
#
# Several of the services noctalia integrates with (NetworkManager, bluetooth,
# upower, power-profiles-daemon) are already turned on by
# programs.noctalia.recommendedServices in ./desktop.nix. What is left here is
# audio, removable media, and the deliberate omissions.
{ pkgs, ... }:
{
  # ── Packet capture ───────────────────────────────────
  # programs.wireshark.package defaults to wireshark-cli (tshark, dumpcap,
  # capinfos, mergecap, ... — no GUI, no .desktop entry). Overriding it to
  # wireshark pulls in the Qt GUI too, which is what puts an entry in the
  # launcher. It also grants dumpcap cap_net_raw+cap_net_admin via a setcap
  # wrapper, so members of the "wireshark" group can capture without sudo.
  # Membership is granted in extraGroups in nix/hosts/laptop/default.nix.
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };

  # ── Audio ────────────────────────────────────────────
  # No WirePlumber configuration on purpose. WirePlumber's default is to keep
  # A2DP for playback and switch to HSP/HFP when an app opens the mic; on the
  # Arctis Nova Pro that switch is abrupt and can sound like audio dropped out.
  # The behaviour is kept anyway — losing quality while talking beats losing
  # the mic. Setting bluetooth.autoswitch-to-headset-profile = false was tried
  # and rejected. See CLAUDE.md §8.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # ── Removable media ──────────────────────────────────
  # udisks2 only, with no automount daemon: nothing mounts on plug, by design.
  # Mounting happens from yazi (`M`, mount.yazi plugin) or `udisksctl mount`.
  # The session is local and active, so polkit authorises it with no password
  # and no agent. Do not add udiskie, gvfs or fstab entries for USB sticks —
  # they would be a second owner of the same state.
  services.udisks2.enable = true;

  # ── Containers ───────────────────────────────────────
  # Rootful docker, reached through the docker group (see extraGroups in
  # nix/hosts/laptop/default.nix). Group membership is root-equivalent — that
  # is the trade taken here instead of rootless mode.
  #
  # enableOnBoot = false does not mean "start it by hand": docker.socket is
  # still wanted by sockets.target, so the daemon comes up on the first docker
  # command and costs nothing until then. What it does give up is containers
  # with a restart policy — they stay down after a reboot until something
  # touches the socket.
  #
  # No docker-compose package anywhere: pkgs.docker already bundles the compose
  # and buildx CLI plugins, so `docker compose` works out of the box and a
  # second copy would only shadow it.
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
  };

  # ── Bluetooth ────────────────────────────────────────
  # hardware.bluetooth.enable comes from recommendedServices; this only says
  # not to power the adapter on at boot.
  hardware.bluetooth.powerOnBoot = false;
}
