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
    zip
    unzip

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
    awscli2

    # ── C/C++ toolchain ──
    # gnumake is the piece that actually runs a Makefile; cmake only writes
    # one. Do NOT add pkgs.clang beside gcc — both ship bin/cc and bin/c++ and
    # home-manager aborts on the collision. clang-tools is the tooling half
    # (clangd, clang-format, clang-tidy) with no compiler drivers, so it fits.
    gcc
    gnumake
    cmake
    ninja # cmake -G Ninja; the backend most upstreams assume now
    pkg-config # every autotools/cmake dependency lookup expects it on PATH
    gdb
    clang-tools # clangd LSP + clang-format
    # `bear -- make` writes the compile_commands.json that clangd needs to
    # understand a plain Makefile project (cmake emits one on its own).
    bear

    # ── Containers ──
    # The docker CLI and daemon come from virtualisation.docker in
    # nix/system/services.nix, not from here.
    lazydocker

    #lsp
    nil

    # Tools
    obsidian
    localsend

    # general software
    spotify
  ];

  # yazi's mount plugin (bound to `M` in yazi/keymap.toml) is vendored in the
  # repo under yazi/.config/yazi/plugins/mount.yazi and reaches yazi through
  # the directory symlink, so pkgs.yaziPlugins.mount is not wired in here —
  # having both would be two copies of the same plugin.
}
