#!/usr/bin/env bash
# Bootstrap this configuration on a freshly installed NixOS.
#
# Requirements: a terminal, a network connection, and git. Nothing else — the
# rest is pulled by Nix. Safe to re-run: every step is idempotent.
#
# Run it either way:
#   curl -fsSL https://raw.githubusercontent.com/goslynn/dailydrive-dots/nixos/install.sh | bash
#   git clone -b nixos <repo> ~/.dotfiles && ~/.dotfiles/install.sh
#
# Full walkthrough, including partitioning and the minimal install that comes
# before this: INSTALL.md
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/goslynn/dailydrive-dots.git}"
REPO_BRANCH="${REPO_BRANCH:-nixos}"
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
HOST="${HOST:-laptop}"

# Flakes are not enabled yet on a stock install; this config turns them on, but
# the very first build has to ask for them on the command line.
NIX_FLAGS=(--extra-experimental-features 'nix-command flakes')

BOLD=$'\033[1m'; RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RESET=$'\033[0m'
step() { printf '\n%s==>%s %s%s\n' "$BOLD$GREEN" "$RESET" "$BOLD" "$*$RESET"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '%s !! %s%s\n' "$YELLOW" "$*" "$RESET"; }
die()  { printf '%s !! %s%s\n' "$RED" "$*" "$RESET" >&2; exit 1; }

# ── 1. Sanity checks ─────────────────────────────────
step "Checking the environment"

[[ -e /etc/NIXOS ]] || die "This is not NixOS. Run INSTALL.md's steps 1-2 first."
[[ $EUID -ne 0 ]] || die "Run this as your normal user, not root. It calls sudo where it needs to."
command -v git >/dev/null || die "git not found. Install it with: nix-shell -p git"

if ! curl -fsS --max-time 10 -o /dev/null https://cache.nixos.org/nix-cache-info; then
    die "No route to cache.nixos.org. Connect to the network first (nmtui)."
fi
info "NixOS, network up, git present."

# ── 2. Repository ────────────────────────────────────
step "Fetching the configuration into $DOTFILES"

if [[ -d $DOTFILES/.git ]]; then
    info "Already cloned; fetching."
    git -C "$DOTFILES" fetch --quiet origin "$REPO_BRANCH"
    if [[ -n $(git -C "$DOTFILES" status --porcelain) ]]; then
        warn "Working tree has local changes — leaving them alone, not pulling."
    else
        git -C "$DOTFILES" checkout --quiet "$REPO_BRANCH"
        git -C "$DOTFILES" merge --quiet --ff-only "origin/$REPO_BRANCH"
    fi
else
    git clone --branch "$REPO_BRANCH" "$REPO_URL" "$DOTFILES"
fi

# ── 3. Hardware configuration ────────────────────────
step "Wiring in this machine's hardware configuration"

# The copy in git is a placeholder that describes no real disk; it exists only
# so the flake evaluates before an install. The real one comes from
# nixos-generate-config, which nixos-install already ran.
HW_SRC=/etc/nixos/hardware-configuration.nix
HW_DST="$DOTFILES/nix/hosts/$HOST/hardware-configuration.nix"

[[ -f $HW_SRC ]] || die "$HW_SRC missing. Generate it with: sudo nixos-generate-config"

if cmp -s "$HW_SRC" "$HW_DST"; then
    info "Already current."
else
    cp "$HW_SRC" "$HW_DST"
    info "Copied $HW_SRC -> ${HW_DST#"$DOTFILES"/}"
    warn "This file describes THIS machine's disks. Commit it, but do not"
    warn "expect it to work on another one."
fi

# ── 4. Build the system ──────────────────────────────
step "Building and activating the system (this takes a while the first time)"
info "sudo nixos-rebuild switch --flake $DOTFILES#$HOST"
sudo nixos-rebuild "${NIX_FLAGS[@]}" switch --flake "$DOTFILES#$HOST"

# ── 5. noctalia's configuration ──────────────────────
step "Restoring noctalia's configuration"

# noctalia layers its config: hand-written TOML in ~/.config/noctalia, and GUI
# overrides in ~/.local/state/noctalia/settings.toml, where the state layer
# always wins. So the repo's export goes into the config layer, and the state
# layer has to be cleared or it would mask what we just restored.
# This is why noctalia/ is not deployed as a symlink. See CLAUDE.md §1.
NOCTALIA_SRC="$DOTFILES/noctalia/.config/noctalia/config.toml"
NOCTALIA_DST="$HOME/.config/noctalia/config.toml"

if [[ -f $NOCTALIA_SRC ]]; then
    if [[ -f $NOCTALIA_DST ]] && ! cmp -s "$NOCTALIA_SRC" "$NOCTALIA_DST"; then
        backup="$NOCTALIA_DST.bak.$(date +%Y%m%d-%H%M%S)"
        cp "$NOCTALIA_DST" "$backup"
        warn "Existing config.toml differed; kept a copy at $backup"
    fi
    mkdir -p "$(dirname "$NOCTALIA_DST")"
    cp "$NOCTALIA_SRC" "$NOCTALIA_DST"
    rm -f "$HOME/.local/state/noctalia/settings.toml"
    info "Restored config.toml and cleared the GUI override layer."

    if command -v noctalia >/dev/null && ! noctalia config validate; then
        warn "noctalia rejected the restored config — check it before logging in."
    fi
else
    warn "$NOCTALIA_SRC not found; skipping."
fi

# ── 6. User content ──────────────────────────────────
step "Preparing directories for content that is not in this repo"
mkdir -p "$HOME/Pictures/Wallpapers"
info "~/Pictures/Wallpapers — restore your gallery here from backup."

# ── 7. What is left to do by hand ────────────────────
step "Done. Remaining manual steps"
cat <<EOF

  1. Set your password if you have not:      passwd
  2. Restore from your backups:
       - ~/Pictures/Wallpapers/   (noctalia's wallpaper picker reads this)
       - SSH and GPG keys
       - git identity: git config --global user.name / user.email
         (this repo versions ~/.config/git/ignore only, not your identity)
  3. Reboot.                                 sudo reboot

  On the first login, with a working network connection:
  4. noctalia downloads its community template (yazi) and the
     "Catppuccin Mocha Lavender" palette from api.noctalia.dev. Without a
     network the theme comes up degraded until the next connection.
  5. Push the look to the login screen:
       noctalia settings -> Security -> Noctalia Greeter -> Sync Now
     Repeat this whenever you change wallpaper or palette — the greeter does
     not follow the shell automatically.

EOF
