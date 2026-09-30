# ~/.config/zsh/.zshenv

# ---------- Zsh directories ----------
# Point zsh to config in ~/.config instead of $HOME
export ZDOTDIR="$HOME/.config/zsh"

# ---------- XDG base directories ----------
# Centralizes config/cache/data locations
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# ---------- Editor ----------
# Default editor used by git, crontab, etc.
export EDITOR="micro"
export VISUAL="micro"

# ---------- Pager ----------
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="bat -l man -p"
elif command -v batcat >/dev/null 2>&1; then
  export MANPAGER="batcat -l man -p"
fi

# ---------- GPG ----------
export GPG_TTY=$(tty)

# ---------- PATH ----------
# Personal binaries/scripts
export PATH="$HOME/.local/bin:$PATH"

# `go install` target (GOPATH defaults to ~/go). Keeps locally built Go tools —
# awsacademy, mainly — on PATH without a nixos-rebuild per iteration. Nix is
# still the right home for anything that has stopped changing.
export PATH="$HOME/go/bin:$PATH"

# ---------- libvirt ----------
# Which libvirt instance virsh talks to. Not a preference: without this, virsh
# connects to qemu:///session — a *separate*, per-user libvirt with its own
# (empty) list of domains — so `virsh list --all` comes back blank and the VMs
# look like they vanished. The lab lives on the system instance, which is what
# virtualisation.nix configures and what membership in the "libvirtd" group
# grants access to (no sudo needed; polkit authorises the group).
#
# Only virsh and the other CLI tools read this. virt-manager keeps its own
# connection list in dconf and defaults to qemu:///system on its own, so the
# GUI is unaffected either way.
export LIBVIRT_DEFAULT_URI="qemu:///system"
