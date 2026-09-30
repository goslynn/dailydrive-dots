# Networking: local service discovery (mDNS/DNS-SD and SSDP) plus the firewall
# holes it needs.
#
# Nothing here brings up the link. NetworkManager comes from
# programs.noctalia.recommendedServices in ./desktop.nix and wlp2s0 takes its
# address by DHCP. What this module adds is *discovery*, which on a stock NixOS
# silently does not work: networking.firewall is enabled by default with a
# default-deny INPUT policy, and the only inbound UDP it accepts is what
# conntrack can tie back to an outbound flow.
#
# Every LAN discovery protocol breaks exactly that assumption. The question is
# sent to a multicast group and the answer comes back from the *device's own*
# unicast address, so the reply never matches the conntrack entry (whose
# expected reply tuple is the multicast group) and lands in nixos-fw-refuse.
# The symptom is asymmetric in a way that looks like a network problem and is
# not: this laptop's Cast menu stays empty while a phone on the same AP finds
# the TV instantly, because the phone's OS has no such firewall. Same reason
# casting worked from this hardware under a distro whose firewall shipped an
# mdns/ssdp allowance (or none at all).
{ lib, ... }:
let
  # The LAN-facing interfaces. This is a single-NIC laptop — only the Realtek
  # WiFi card; see the network notes in ./virtualisation.nix for why there is no
  # RJ45 here. Both avahi and the firewall rules below are scoped to this list,
  # so a USB ethernet dongle (which enumerates as some enp*u* name) is a
  # one-line change in one place.
  #
  # The scoping is not tidiness. The other interfaces on this host are libvirt's
  # virbr0 / virbr-lab / virbr-air and docker0, and the lab deliberately runs
  # vulnerable guests (see ./virtualisation.nix). Answering mDNS on those
  # bridges, and above all opening the ephemeral UDP range to them, would hand a
  # compromised target a far bigger slice of the host than the home WiFi gets.
  lanInterfaces = [ "wlp2s0" ];
in
{
  # ── mDNS / DNS-SD ────────────────────────────────────
  # Worth being explicit about what this daemon is and is not doing for Cast:
  # Chromium (so Brave) carries its own mDNS client and never talks to avahi, so
  # avahi is NOT what puts the TV in Brave's Cast menu — the firewall block
  # below is. avahi is here for everything else that expects DNS-SD on a
  # desktop: `avahi-browse -rt _googlecast._tcp` as the way to test discovery
  # without a browser in the loop, .local resolution for the TV and for lab
  # guests, and CLI casting tools (go-chromecast, the VLC/mpv wrappers) which
  # all discover through libavahi instead of rolling their own responder.
  services.avahi = {
    enable = true;

    # Adds mdns4 to nsswitch, which is what makes <host>.local resolve.
    # Deliberately not nssmdns6: that would put mdns6 in front of AAAA lookups
    # and everything answering on this LAN does so over IPv4. The daemon still
    # speaks mDNS over IPv6 (ff02::fb) on its own, via services.avahi.ipv6.
    nssmdns4 = true;

    allowInterfaces = lanInterfaces;

    # Publishing stays off (the whole publish.* set defaults to false): this
    # host browses and resolves without announcing itself, which is all that
    # casting needs — the laptop is the one doing the looking.

    # openFirewall defaults to *true* and would open UDP 5353 on every
    # interface, bridges included. The interface-scoped rule below does the same
    # job for wlp2s0 only, so this has to be turned off explicitly.
    openFirewall = false;
  };

  # ── Firewall: discovery ──────────────────────────────
  networking.firewall.interfaces = lib.genAttrs lanInterfaces (_: {
    allowedUDPPorts = [
      # mDNS. `_googlecast._tcp.local` answers arrive as multicast to
      # 224.0.0.251:5353 (ff02::fb for v6) — addressed to the group, not to the
      # socket that asked — so conntrack cannot match them and they are refused
      # without this. This single rule is the one that fixes Google Cast.
      5353

      # SSDP, which is Chromium's second discovery path (DIAL) and the one that
      # finds smart TVs that are not native Chromecast hardware. Devices also
      # announce themselves unsolicited, by NOTIFY to 239.255.255.250:1900 —
      # that is what makes a TV powered on *after* the browser show up without
      # reopening the Cast menu.
      1900
    ];

    allowedUDPPortRanges = [
      # Unicast answers to multicast questions. Chromium's DIAL socket sends
      # M-SEARCH from an ephemeral port to 239.255.255.250:1900, and UPnP has
      # the device reply with a *unicast* datagram to that port, sourced from
      # its own address — which again is not the reply tuple conntrack recorded,
      # so it is refused. mDNS responders that honour the QU (unicast-response)
      # bit do the same thing.
      #
      # The bounds mirror this host's net.ipv4.ip_local_port_range exactly
      # (`sysctl net.ipv4.ip_local_port_range` → 32768 60999); re-check it
      # before narrowing them, since the kernel picks source ports from there.
      #
      # This is the deliberate hole, and the reason for the interface scoping
      # above: on wlp2s0, any UDP port a local program binds in this range is
      # reachable from the home LAN for as long as it stays bound. Ports with
      # nothing listening just answer ICMP port-unreachable, so the exposure is
      # whatever happens to be listening, not the range itself.
      {
        from = 32768;
        to = 60999;
      }
    ];

    # No TCP here on purpose. The advice passed around for Chromecast usually
    # adds 8008/8009, but those ports belong to the *TV*: this machine connects
    # out to them (8009 is cast v2 over TLS, 8008 the plain HTTP endpoint) and
    # the OUTPUT chain is unrestricted, so an inbound rule for them would be a
    # hole that fixes nothing. Tab/screen mirroring needs nothing either — Chrome
    # opens that RTP flow outbound itself, so conntrack already covers the RTCP
    # coming back.
  });
}
