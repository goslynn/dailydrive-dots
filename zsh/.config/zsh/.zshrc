# Powerful but minimal zsh configuration
# Author: Radley E. Sidwell-Lewis
# GitHub: https://www.github.com/radleylewis/zsh
#
# Uses:
#   Plugins:      fast-syntax-highlighting, zsh-autosuggestions,
#                 zsh-history-substring-search
#   Prompt:       starship
#   Navigation:   zoxide, fzf, fd
#   CLI tools:    eza, bat, nvim, ripgrep
#   Node:         nvm

# =========================================================
# History
# =========================================================

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

# zsh won't create HISTFILE's parent dir itself — it just silently gives up
# writing history if $XDG_STATE_HOME/zsh doesn't exist yet, which on a fresh
# home (or after a boot that never had this dir) means every session's
# history dies with the shell instead of persisting.
[[ -d ${HISTFILE:h} ]] || mkdir -p ${HISTFILE:h}

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

# =========================================================
# Shell behaviour
# =========================================================

setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT  # sort file10 after file9, not after file1

# =========================================================
# Smart directory navigation & lf
# =========================================================

#LF_ICONS=$(cat ~/.config/lf/icons | tr '\n' ':')
#export LF_ICONS

# Initialize zoxide
eval "$(zoxide init zsh)"

# =========================================================
# Completion
# =========================================================

# Load completion system
autoload -Uz compinit

# Initialize completion with cached metadata file
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

# Enable interactive completion menu selection
zstyle ':completion:*' menu select

# Make completion case-insensitive
# Example: "doc" can complete to "Documents"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # lowercase input matches upper and lower

# =========================================================
# Fuzzy finder
# =========================================================

# Keybindings + completion straight from the binary, so this doesn't depend on
# where the distro drops the shell snippets (/usr/share/fzf on Arch,
# $out/share/fzf in the Nix store). Needs fzf >= 0.48.
command -v fzf >/dev/null && source <(fzf --zsh)


# =========================================================
# Modular Config Files
# =========================================================

# fzf configuration
source "$ZDOTDIR/fzf.zsh"

# Aliases
source "$ZDOTDIR/aliases.zsh"

# Custom keybindings
source "$ZDOTDIR/bindings.zsh"

# Plugins and plugin manager
source "$ZDOTDIR/plugins.zsh"

# Prompt/theme
source "$ZDOTDIR/prompt.zsh"

# =========================================================
# jbang
# =========================================================
# The binary comes from the package manager, so no PATH juggling here.
alias j!=jbang

# =========================================================
# FNM
# =========================================================
# No FNM_PATH: fnm itself is on PATH from the package manager, and `fnm env`
# exports the install dir for the Node versions it manages.
command -v fnm >/dev/null && eval "$(fnm env --shell zsh)"

# =========================================================
# kitty shell integration (manual)
# =========================================================
# The system zshenv (/etc/zsh/zshenv on Arch, /etc/zshenv on NixOS) overwrites
# ZDOTDIR, clobbering the value kitty injects for its automatic integration, so
# we load it by hand (kitty.conf sets `shell_integration no-rc`). Without this
# kitty can't detect the shell is idle at the prompt and asks "It is running:
# /usr/bin/zsh" when closing an idle window.
if [[ -n "$KITTY_INSTALLATION_DIR" ]]; then
  export KITTY_SHELL_INTEGRATION="enabled"
  autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
  kitty-integration
  unfunction kitty-integration
fi

# pnpm
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
