{
  inputs,
  lib,
  pkgs,
  unstable,
  ...
}:

let
  # Use the unwrapped macOS app to preserve upstream Developer ID signing.
  # The wrapped default package replaces Contents/MacOS/glide with a shell
  # wrapper, which invalidates the application bundle signature.
  glide = inputs.glide.packages.${pkgs.stdenv.hostPlatform.system}.glide-browser-bin-unwrapped;

  gitHunks = pkgs.stdenvNoCC.mkDerivation {
    pname = "git-hunks";
    version = "0-unstable-2024-11-13";

    src = pkgs.fetchFromGitHub {
      owner = "rockorager";
      repo = "git-hunks";
      rev = "482baff749d3267f01a35bc27e08d949391cb3a4";
      hash = "sha256-0jUN9GDSK6AhkYJfQQv77mpa63Rh5jSDVIgNHNaQqyA=";
    };

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 git-hunks "$out/bin/git-hunks"
      install -Dm644 git-hunks.1 "$out/share/man/man1/git-hunks.1"
      runHook postInstall
    '';

    meta = {
      description = "Non-interactive selective hunk staging for git";
      homepage = "https://github.com/rockorager/git-hunks";
      license = lib.licenses.mit;
      mainProgram = "git-hunks";
    };
  };
in
{
  programs._1password = {
    enable = true;
    package = unstable._1password-cli;
  };

  environment.systemPackages = [
    # Unfree
    unstable._1password-cli
    unstable.claude-code

    # Language/runtime and toolchains.
    glide
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
    gitHunks
    unstable.git-filter-repo
    unstable.glow
    unstable.gnumake
    unstable.gojq
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
    unstable.mmdbctl
    unstable.rsync
    unstable.sad
    unstable.watch
    unstable.yq
    unstable.yt-dlp

    # Docker stuff.
    unstable.docker-client
    unstable.docker-buildx
    unstable.docker-compose

    # Neovim/general language servers and formatters not owned by
    # language runtimes/toolchains.
    unstable.bash-language-server
    unstable.clang-tools
    unstable.fish-lsp
    unstable.fishPlugins.forgit
    unstable.lua-language-server
    unstable.nixd
    unstable.nixfmt
    unstable.protobuf-language-server
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
