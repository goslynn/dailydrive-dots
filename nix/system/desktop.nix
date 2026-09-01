# Desktop: Hyprland compositor, noctalia shell, portals, fonts, themes, zsh.
# The login screen lives in ./greeter.nix.
{ pkgs, ... }:
{
  # ── GPU ──────────────────────────────────────────────
  # hardware-configuration.nix leaves boot.initrd.kernelModules empty, so
  # amdgpu only loads during the normal boot stage — several seconds after
  # multi-user.target, once udev gets around to it. greetd.service has no
  # dependency on the GPU being ready (only on getty@tty1/plymouth-quit-wait),
  # so it starts noctalia-greeter-compositor first, which fails to open any
  # DRM/KMS device, exits instantly, and does that 5x within ~3s — hitting
  # systemd's start-limit-hit and staying dead for the rest of the boot,
  # well before amdgpu's own "detected ip block" lines even show up in the
  # kernel log. That is the boot hang this laptop hits: not a noctalia
  # crash, but greetd racing ahead of a GPU driver that isn't loaded yet.
  # Loading amdgpu from the initrd (early KMS) makes /dev/dri ready before
  # userspace starts, closing the race.
  boot.initrd.kernelModules = [ "amdgpu" ];

  # ── Compositor ───────────────────────────────────────
  # The Lua config itself is not managed here — it is symlinked out of
  # ~/.dotfiles by home-manager (see nix/home/dotfiles.nix), exactly as stow
  # did on Arch.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true; # conf.d/xwayland.lua sets force_zero_scaling
  };

  # NixOS only links a short allowlist of /share subdirs into
  # /run/current-system/sw. Two things here need paths outside that list:
  #
  #   wayland-sessions  the greeter enumerates sessions from
  #                     /run/current-system/sw/share/wayland-sessions; greetd
  #                     starts with an empty environment, so XDG_DATA_DIRS
  #                     (which services.displayManager would set) is no help.
  #                     Without this the greeter offers no session to log into.
  #   …termfilechooser  holds yazi-wrapper.sh, referenced by absolute path from
  #                     xdg-misc/.config/xdg-desktop-portal-termfilechooser/config
  #   Kvantum           catppuccin-kvantum's theme. The Kvantum style plugin
  #                     looks for <dir>/Kvantum/<name>/ in every XDG data dir,
  #                     and /run/current-system/sw/share is one of them — but
  #                     only for the subdirectories linked here.
  #   qt6ct             the Catppuccin colour scheme from catppuccin-qt5ct,
  #                     referenced by absolute path from
  #                     qt/.config/qt6ct/qt6ct.conf (color_scheme_path)
  #
  # Getting either of the last two wrong fails quietly: Qt apps just come up
  # with the default Fusion palette and no one says why.
  #
  # /share/hypr is already added by programs.hyprland, which is what puts the
  # Lua API stubs at /run/current-system/sw/share/hypr/stubs/hl.meta.lua.
  environment.pathsToLink = [
    "/share/wayland-sessions"
    "/share/xdg-desktop-portal-termfilechooser"
    "/share/Kvantum"
    "/share/qt6ct"
  ];

  # ── Portals ──────────────────────────────────────────
  # programs.hyprland already enables xdg.portal with its own portal; these are
  # the extras. Which backend handles the file chooser is decided by the user
  # config in xdg-misc/.config/xdg-desktop-portal/hyprland-portals.conf.
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-gtk
    xdg-desktop-portal-termfilechooser
  ];

  # These portals are all Wants= of graphical-session.target, and
  # xdg-desktop-portal.service additionally carries
  # Requisite=graphical-session.target — so with that target down, every portal
  # D-Bus activation fails and apps quietly use their own built-in dialogs
  # instead. Nothing on this system raises the target on its own (greetd execs
  # Hyprland directly, and noctalia is deliberately not a systemd service), so
  # conf.d/autostart.lua starts nixos-fake-graphical-session.target at session
  # startup. See the comment there.

  # ── Browser PDF policy ───────────────────────────────
  # mimeapps.list only governs what opens a PDF *file*; a PDF served over http
  # never reaches it, because Chromium's bundled PDF viewer claims the
  # navigation first. AlwaysOpenPdfExternally disables that viewer, so Brave
  # hands the file to the download flow and opening it goes through xdg-open →
  # application/pdf=sioyek.desktop.
  #
  # Path confirmed against the binary: brave-origin reads both
  # /etc/brave/policies and /etc/chromium/policies (`grep -a` on
  # opt/brave.com/*/brave).
  environment.etc."brave/policies/managed/pdf.json".text = builtins.toJSON {
    AlwaysOpenPdfExternally = true;
  };

  # ── Shell (noctalia) ─────────────────────────────────
  # systemd.enable stays off on purpose: conf.d/autostart.lua launches noctalia
  # from hl.on("hyprland.start", ...), and that stays the single owner of its
  # lifecycle, same as on Arch.
  #
  # recommendedServices pulls in NetworkManager, bluetooth, upower and a power
  # profile daemon with mkDefault — the integrations noctalia's control center
  # expects. See nix/system/services.nix for the rest.
  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
  };

  # ── Fonts ────────────────────────────────────────────
  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-cove # kitty.conf: CaskaydiaCove Nerd Font
    noto-fonts
    noto-fonts-color-emoji
    (callPackage ../pkgs/google-sans.nix { }) # noctalia config.toml font_family
  ];

  # ── Qt ───────────────────────────────────────────────
  # This is the piece that makes any Qt theming possible at all on NixOS, and
  # it is easy to miss: nixpkgs wraps every Qt app with a QT_PLUGIN_PATH that
  # lists only that app's own dependencies, so a platform theme or style plugin
  # installed into a profile is invisible to it. qt.enable sets
  # environment.profileRelativeSessionVariables.QT_PLUGIN_PATH (plus
  # QML2_IMPORT_PATH), and because makeCWrapper *prefixes* rather than replaces,
  # the wrapped apps keep it. Without this line qt6ct and Kvantum below are
  # dead weight.
  #
  # platformTheme/style are left null on purpose. The module's "qt5ct" option
  # would drag in the whole Qt5 stack (libsForQt5.qt5ct) for zero Qt5 apps —
  # `nix-store -qR /run/current-system | grep qtbase-5` comes back empty — and
  # its style/platformTheme values are exported through environment.variables,
  # which would be a second place declaring what conf.d/env.lua already owns.
  qt.enable = true;

  # ── Themes ───────────────────────────────────────────
  # Everything here is Catppuccin Frappé with a lavender accent — the same
  # palette noctalia is set to (theme.source = "community",
  # community_palette = "Catppuccin Frappe Lavender"). Nothing syncs the two
  # automatically: noctalia has no GTK/Qt template, so if its palette ever
  # changes, this side has to be changed by hand.
  #
  # That flavour/accent pair is spelled out in six places and they all have to
  # agree:
  #
  #   this file                                 the packages themselves
  #   conf.d/env.lua                            GTK_THEME
  #   gtk/.config/gtk-{3,4}.0/settings.ini      theme / icons / cursor names
  #   qt/.config/qt6ct/qt6ct.conf               color_scheme_path, icon_theme
  #   qt/.config/Kvantum/kvantum.kvconfig       Kvantum theme name
  #   nix/home/theming.nix                      the gsettings the portal reads
  #
  # Resulting names:
  #   catppuccin-cursors.frappeDark -> share/icons/catppuccin-frappe-dark-cursors
  #   catppuccin-gtk                -> share/themes/catppuccin-frappe-lavender-standard
  #   catppuccin-kvantum            -> share/Kvantum/catppuccin-frappe-lavender
  #   catppuccin-qt5ct              -> share/qt6ct/colors/catppuccin-frappe-lavender.conf
  #   catppuccin-papirus-folders    -> share/icons/Papirus-Dark
  #
  # Note the GTK theme has NO "+default" suffix here, unlike the AUR build:
  # nixpkgs carries fix-inconsistent-theme-name.patch, which drops it. env.lua
  # on this branch is set accordingly.
  environment.systemPackages = with pkgs; [
    # frappeDark, not frappeLavender: "Dark" is the neutral dark cursor, which
    # is the shape this config has always used. catppuccin-cursors also has an
    # accent-tinted frappeLavender if you'd rather the pointer carry the accent
    # too — it renames the theme dir, so env.lua and greeter.nix follow.
    catppuccin-cursors.frappeDark
    (catppuccin-gtk.override {
      variant = "frappe";
      accents = [ "lavender" ];
      size = "standard";
    })

    # Qt: the config tool (its platformtheme plugin is what QT_QPA_PLATFORMTHEME
    # resolves to), the widget style, and the palette.
    #
    # qt6ct's plugin registers BOTH the "qt6ct" and "qt5ct" keys, which is why
    # NixOS' own qt module gets away with exporting "qt5ct" for Qt6 apps.
    qt6Packages.qt6ct
    qt6Packages.qtstyleplugin-kvantum
    (catppuccin-kvantum.override {
      variant = "frappe";
      accent = "lavender";
    })
    catppuccin-qt5ct # ships share/qt{5,6}ct/colors/*.conf

    # Icon theme, shared by GTK and Qt. catppuccin-papirus-folders is a full
    # recoloured copy of Papirus, so papirus-icon-theme must NOT also be
    # installed — both provide share/icons/Papirus-Dark and buildEnv would
    # collide.
    (catppuccin-papirus-folders.override {
      flavor = "frappe";
      accent = "lavender";
    })
  ];

  # ── gsettings ────────────────────────────────────────
  # dconf is what xdg-desktop-portal-gtk reads to answer
  # org.freedesktop.impl.portal.Settings, and that answer is how Chromium /
  # Electron / Qt6 / libadwaita decide whether to render dark. GTK_THEME does
  # not reach any of them. The values live in nix/home/theming.nix; this only
  # provides the daemon and the schema plumbing.
  programs.dconf.enable = true;

  # ── Shell ────────────────────────────────────────────
  programs.zsh = {
    enable = true;

    # Replaces the hand-installed /etc/zsh/zshenv from the Arch setup
    # (zsh/etc/zsh/zshenv in this repo). shellInit lands in /etc/zshenv, which
    # zsh reads before anything under $ZDOTDIR.
    shellInit = ''
      if [[ -z "$XDG_CONFIG_HOME" ]]; then
        export XDG_CONFIG_HOME="$HOME/.config"
      fi

      if [[ -d "$XDG_CONFIG_HOME/zsh" ]]; then
        export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
      fi
    '';

    # Keep the fpath wiring and nix-zsh-completions, but let our own .zshrc run
    # compinit — it uses a custom dump path under $XDG_CACHE_HOME.
    enableCompletion = true;
    enableGlobalCompInit = false;

    # starship owns the prompt (zsh/prompt.zsh).
    promptInit = "";
  };
}
