{
  lib,
  pkgs,
  unstable,
  inputs,
  ...
}:

let
  derivations = import ./derivations.nix {
    inherit
      lib
      pkgs
      unstable
      inputs
      ;
  };
  inherit (derivations)
    glide
    bttf
    gitHunks
    cloudflareCf
    wb
    glimpseui
    ;
in
{
  programs._1password = {
    enable = true;
    package = unstable._1password-cli;
  };

  environment.variables = {
    WB_UPDATE_CHECK = lib.mkDefault "off";
    WB_NO_UPDATE_CHECK = lib.mkDefault "1";
    WB_SKILL_AUTO_UPDATE = lib.mkDefault "off";
    WB_NO_SKILL_AUTO_UPDATE = lib.mkDefault "1";
  };

  environment.systemPackages = [
    # Unfree
    unstable._1password-cli
    unstable.claude-code

    # Language/runtime and toolchains.
    glide
    bttf
    unstable.biome
    unstable.bun
    unstable.go
    unstable.lua
    unstable.luarocks
    unstable.neovim
    unstable.nodejs
    unstable.openssh
    unstable.python3
    unstable.rustup
    unstable.uv
    unstable.wasmer
    unstable.wasmtime
    unstable.zig

    # Shell/git/search
    unstable.git
    unstable.as-tree
    unstable.chafa
    unstable.colordiff
    unstable.curl
    unstable.diff-so-fancy
    unstable.difftastic
    unstable.duckdb
    unstable.ffmpeg
    unstable.gh
    unstable.ghq
    unstable.agent-browser
    unstable.cloudflared
    cloudflareCf
    gitHunks
    wb
    glimpseui
    unstable.git-filter-repo
    unstable.glow
    unstable.gnumake
    unstable.gojq
    unstable.gofumpt
    unstable.gopls
    unstable.gotest
    unstable.gotestsum
    unstable.gotools # includes goimports
    unstable.gum
    unstable.htop
    unstable.httpie
    unstable.hyperfine
    unstable.jq
    unstable.just
    unstable.less
    unstable.massren
    unstable.mergiraf
    unstable.mpv
    unstable.rsync
    unstable.ruff
    unstable.sad
    unstable.tree
    unstable.watch
    unstable.yq

    # Docker stuff.
    unstable.docker-client
    unstable.docker-buildx
    unstable.docker-compose

    # Neovim/general language servers and formatters not owned by
    # language runtimes/toolchains.
    unstable.bash-language-server
    unstable.clang-tools
    unstable.csharpier
    unstable.fish-lsp
    unstable.fishPlugins.forgit
    unstable.lua-language-server
    unstable.nixd
    unstable.nixfmt
    unstable.protobuf-language-server
    unstable.roslyn-ls
    unstable.shellcheck
    unstable.shfmt
    unstable.sourcekit-lsp
    unstable.stylua
    unstable.tailwindcss-language-server
    unstable.tree-sitter
    unstable.taplo
    unstable.terraform-ls
    unstable.typos-lsp
    unstable.typescript-language-server
    unstable.yaml-language-server
    unstable.zls
  ];

  environment.shells = [ pkgs.fish ];
  programs.fish.enable = true;
}
