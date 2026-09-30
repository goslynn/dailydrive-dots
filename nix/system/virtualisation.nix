# Virtualisation: QEMU/KVM through libvirt, for the cybersecurity class lab —
# one Kali guest plus deliberately vulnerable targets.
#
# Nothing here is declarative about the *guests*. They are foreign distros, and
# their domain XML is libvirt state under /var/lib/libvirt, not something this
# repo owns. What this module does instead is provide the hypervisor and keep
# every network path that might be wanted mid-session already enabled, so
# picking between them is a hot-plug away rather than a rebuild — see the
# network section below for the four of them and what each one costs.
{ pkgs, ... }:
{
  # ── Hypervisor ───────────────────────────────────────
  virtualisation.libvirtd = {
    enable = true;

    # Domains do not start at boot. On a 12 GB machine, a guest with 4 GiB
    # assigned coming up on its own behind the greeter is the difference
    # between a usable session and one that swaps from the login screen.
    onBoot = "ignore";

    # The default is "suspend": on host shutdown libvirt managed-saves every
    # running domain, dumping guest RAM to /var/lib/libvirt/qemu/save. That is
    # 4 GiB of disk per guest and a poweroff that visibly stalls. "shutdown"
    # sends ACPI poweroff and waits instead; with snapshots there is nothing
    # worth preserving that way.
    onShutdown = "shutdown";

    qemu = {
      # The default is pkgs.qemu, which builds every target QEMU supports —
      # ARM, RISC-V, SPARC, PowerPC, s390x. Only x86_64 guests run here, and
      # qemu_kvm is the same QEMU built with --target-list=host, for a much
      # smaller closure and much shorter rebuilds when nixpkgs bumps it.
      package = pkgs.qemu_kvm;

      # No `ovmf` block here: that submodule was removed in 26.11 and now trips
      # an assertion if set. UEFI is not lost — the module symlinks whatever
      # firmware the qemu package above ships into /run/libvirt/nix-ovmf and
      # generates the descriptor metadata from it. qemu_kvm carries the full
      # edk2 set (60-edk2-x86_64.json plus 50-edk2-x86_64-secure.json, so
      # Secure Boot too), which is why narrowing to --target-list=host costs
      # nothing on the firmware side. Pick the profile per-domain in
      # virt-manager's "Customise before install" screen, not here.

      # Emulated TPM 2.0. Only a Windows 11 guest wants it — but without it
      # that installer dies on its first screen with an error that never
      # mentions the TPM, so it is cheaper to have it here than to debug it.
      swtpm.enable = true;

      # Registers virtiofsd as a vhost-user backend, which is what enables
      # virtio-fs shared directories between host and guest. Much faster than
      # 9p, and it avoids standing up Samba just to get files out of Kali.
      vhostUserPackages = [ pkgs.virtiofsd ];
    };
  };

  # GTK frontend for libvirt. Pulls in virt-viewer and the SPICE client by
  # dependency; virsh ships with libvirt itself. Native Wayland client, so it
  # does not take the XWayland detour.
  programs.virt-manager.enable = true;

  # ── Device passthrough ───────────────────────────────
  # IOMMU is already active without these (25 groups show up in
  # /sys/kernel/iommu_groups on a stock boot, since the firmware enables it).
  # amd_iommu=on is therefore redundant and kept only to state the intent;
  # iommu=pt is the real addition — it puts devices that are *not* assigned to
  # a guest into identity-mapped passthrough mode, which removes the IOMMU
  # translation cost from host DMA. Without it, enabling the IOMMU taxes
  # ordinary host I/O for no benefit.
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
  ];

  # vfio-pci is what a device gets rebound to while a guest owns it. Loading
  # the modules here (with no ids= parameter, so they claim nothing on their
  # own) is what makes `virsh nodedev-detach` work on demand instead of needing
  # a reboot — which is the whole point of keeping the choice for mid-session.
  #
  # Deliberately NOT blacklisting rtw89_8852be: the host uses the WiFi card
  # normally, and libvirt's <hostdev managed='yes'/> unbinds the host driver
  # when the guest starts and hands it back when the guest stops.
  boot.kernelModules = [
    "vfio_pci"
    "vfio_iommu_type1"
    "vfio"
  ];

  # USB redirection over SPICE. This is *the* requirement for using an external
  # WiFi adapter in monitor mode inside Kali: airmon-ng needs the real device,
  # and the driver has to be loaded by the guest kernel rather than the host's.
  # Installs the udev rules and the setuid helper so the redirection does not
  # need root. Prefer this over the PCI passthrough of wlp2s0 described below.
  virtualisation.spiceUSBRedirection.enable = true;

  # ── Networks ─────────────────────────────────────────
  # Four paths, all available at once; a guest picks one per NIC, and NICs
  # hot-plug with `virsh attach-interface` while it runs.
  #
  #   1. "default"  — libvirt's own NAT network on virbr0, 192.168.122.0/24.
  #      Works over WiFi and over ethernet, always. This is Kali's route to the
  #      internet. Not autostarted by libvirt on NixOS; see INSTALL notes.
  #
  #   2. "lab"      — ./libvirt/lab.xml. Isolated: no forwarding out, so no
  #      internet and nothing reaches the LAN, but the host holds 10.10.10.1 on
  #      the bridge and dnsmasq hands out leases. Targets here are reachable
  #      from the host, which is what makes `http://10.10.10.x/dvwa` work in
  #      Brave. This is the everyday lab segment: real layer 2 between guests,
  #      so ARP spoofing, broadcast-based tools (responder, DHCP starvation)
  #      and promiscuous capture all behave like a physical switch.
  #
  #   3. "lab-airgap" — ./libvirt/lab-airgap.xml. Same idea with no <ip> at
  #      all: a bare L2 bridge, no host address, no DHCP, static addressing by
  #      hand. For anything where the target genuinely must not be able to
  #      reach this machine. Slower to set up, which is why it is the second
  #      network and not the only one.
  #
  #   4. macvtap onto a real NIC — no XML here on purpose. This is the "give
  #      the guest a real IP from the house router" case, and it is a runtime
  #      decision because the interface has to be named:
  #
  #        virsh attach-interface <dom> direct <iface> --model virtio --live
  #
  #      It only works over ethernet. Bridging a guest onto *WiFi* cannot work:
  #      an 802.11 station may not present more than one MAC address to the AP
  #      unless both sides speak 4-address/WDS mode, which neither a consumer
  #      AP nor rtw89 does. The guest would ARP into a void. Since this laptop
  #      has no RJ45 (only wlp2s0), <iface> is whatever a USB dongle enumerates
  #      as — an enp*u* name that depends on the port, hence no fixed XML.
  #
  # And the last resort, which is not a network mode but the other half of the
  # question: handing the guest the built-in WiFi card itself, as PCI
  # passthrough of 02:00.0 (Realtek RTL8852BE). It is unusually clean here —
  # that device sits alone in IOMMU group 13, so no ACS override patch is
  # needed — and `managed='yes'` makes it a start/stop affair rather than a
  # reboot. Two things to know before reaching for it: this is the machine's
  # only network interface, so the host goes fully offline for as long as the
  # guest holds it; and while rtw89 does advertise monitor mode, its injection
  # support is the weak part, so the deauth half of most wireless exercises is
  # unreliable regardless of which kernel drives the card. A cheap USB adapter
  # with an mt7612u/ath9k_htc chipset plus option 4 above is the better answer.

  environment.etc = {
    "libvirt-networks/lab.xml".source = ./libvirt/lab.xml;
    "libvirt-networks/lab-airgap.xml".source = ./libvirt/lab-airgap.xml;
  };

  # No systemd unit defining those networks at activation, on purpose. libvirt
  # keeps network definitions in its own store under /var/lib/libvirt and
  # expects to be their only owner — the same reasoning as the udisks2 note in
  # ./services.nix. They get defined once, by hand, from the files above.

  environment.systemPackages = with pkgs; [
    # Kali's prebuilt QEMU images ship as .7z.
    p7zip

    # ISO of signed virtio drivers for Windows guests. Without mounting it as a
    # second CD-ROM, the Windows installer sees no disk on a virtio bus and the
    # only way forward is degrading the bus to SATA.
    virtio-win

    # Reading the passthrough side of the setup: lspci -nnk to find a device's
    # vendor:product and which driver holds it, lsusb to identify a WiFi dongle
    # before redirecting it, iw to check what modes a card actually claims.
    pciutils
    usbutils
    iw
  ];
}
