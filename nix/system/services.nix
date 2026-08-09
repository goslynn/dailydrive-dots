# System services.
#
# Several of the services noctalia integrates with (NetworkManager, bluetooth,
# upower, power-profiles-daemon) are already turned on by
# programs.noctalia.recommendedServices in ./desktop.nix. What is left here is
# audio, removable media, and the deliberate omissions.
{ ... }:
{
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

  # ── Bluetooth ────────────────────────────────────────
  # hardware.bluetooth.enable comes from recommendedServices; this only says
  # not to power the adapter on at boot.
  hardware.bluetooth.powerOnBoot = false;
}
