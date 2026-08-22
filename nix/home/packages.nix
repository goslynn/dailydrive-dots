# User packages. Anything referenced by a config in this repo should be here
# (or in nix/system/packages.nix when it must exist outside the session).
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # ── CLI, referenced by zsh/aliases.zsh and zsh/fzf.zsh ──
    eza # ls/ll/la/tree
    bat # cat, and MANPAGER in .zshenv
    ripgrep # grep
    fd # FZF_DEFAULT_COMMAND
    fzf # Ctrl+F widget; .zshrc sources `fzf --zsh`
    zoxide # eval'd in .zshrc
    starship # zsh/prompt.zsh
    jq

    # ── TUI apps with configs in this repo ──
    yazi
    btop
    micro # EDITOR/VISUAL in .zshenv

    # PDF viewer, wrapped for HiDPI under XWayland.
    (callPackage ../pkgs/sioyek-hidpi.nix { })

    # ── Browser (conf.d/programs.lua) ──
    brave-origin

    # ── Dev toolchain ──
    jdk
    maven
    gradle
    nodejs
    python3
    go
    pnpm
    fnm
    claude-code
    github-cli
    lazygit
    zed-editor-fhs

    #lsp
    nil


    # Tools
    obsidian
    localsend
  ];

  # yazi's mount plugin (bound to `M` in yazi/keymap.toml) is vendored in the
  # repo under yazi/.config/yazi/plugins/mount.yazi and reaches yazi through
  # the directory symlink, so pkgs.yaziPlugins.mount is not wired in here —
  # having both would be two copies of the same plugin.
}
