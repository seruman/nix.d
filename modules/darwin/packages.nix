{ inputs }:

{
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

  bttf = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "bttf";
    version = "0.1.4";

    src = pkgs.fetchurl {
      url = "https://github.com/BurntSushi/bttf/releases/download/${finalAttrs.version}/bttf-${finalAttrs.version}-aarch64-apple-darwin.tar.gz";
      hash = "sha256-QoQyXgnj4r1i7qdugDcB2BdQYZ+VGVblaY0gjDfJvz8=";
    };

    sourceRoot = "bttf-${finalAttrs.version}-aarch64-apple-darwin";

    installPhase = ''
      runHook preInstall
      install -Dm755 bttf "$out/bin/bttf"
      install -Dm644 README.md "$out/share/doc/bttf/README.md"
      install -Dm644 doc/COMPARISON.md "$out/share/doc/bttf/COMPARISON.md"
      install -Dm644 doc/GUIDE.md "$out/share/doc/bttf/GUIDE.md"
      install -Dm644 LICENSE-MIT "$out/share/licenses/bttf/LICENSE-MIT"
      install -Dm644 UNLICENSE "$out/share/licenses/bttf/UNLICENSE"
      runHook postInstall
    '';

    meta = {
      description = "Command line tool for datetime arithmetic, parsing, formatting and more";
      homepage = "https://github.com/BurntSushi/bttf";
      license = with lib.licenses; [
        mit
        unlicense
      ];
      mainProgram = "bttf";
      platforms = [ "aarch64-darwin" ];
    };
  });

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

  cloudflareCf =
    let
      nodejs = unstable.nodejs;
    in
    pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
      pname = "cloudflare-cf";
      version = "0.0.6";

      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/cf/-/cf-${finalAttrs.version}.tgz";
        hash = "sha512-FUTEhDk1lfisq32cXeP+L2nl2eCrVaFQZ21vs+HGk78BnrbaUjtAvw5PbPH6qtWbkqbgjcpWI8sSzwSePU0cTQ==";
      };

      sourceRoot = "package";
      nativeBuildInputs = [ pkgs.makeWrapper ];

      installPhase = ''
        runHook preInstall
        mkdir -p "$out/lib/cloudflare-cf" "$out/bin"
        cp -R bin dist package.json README.md "$out/lib/cloudflare-cf/"
        chmod +x "$out/lib/cloudflare-cf/bin/cf"
        makeWrapper ${nodejs}/bin/node "$out/bin/cf" \
          --add-flags "$out/lib/cloudflare-cf/bin/cf"
        runHook postInstall
      '';

      meta = {
        description = "Technical preview unified command-line interface for Cloudflare";
        homepage = "https://blog.cloudflare.com/cf-cli-local-explorer/";
        license = lib.licenses.mit;
        mainProgram = "cf";
      };
    });
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
