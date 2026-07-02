{
  lib,
  pkgs,
  unstable,
  inputs,
}:

{
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

  wb =
    let
      version = "0.1.5";
      system = pkgs.stdenv.hostPlatform.system;
      release =
        {
          aarch64-darwin = {
            arch = "arm64";
            hash = "sha256-qlNwgsYLhbuj66sTo8b5t4ZrcyZu2Ps6sFCPVHmSNeI=";
          };
          x86_64-darwin = {
            arch = "x86_64";
            hash = "sha256-rb3tU39YCiEXVCJzaWLdbsaGk1ZjRuJlVy45uGixAY0=";
          };
        }
        .${system} or (throw "wb is only packaged for Darwin systems");
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "wb";
      inherit version;

      src = pkgs.fetchzip {
        url = "https://github.com/aduermael/wb/releases/download/v${version}/wb-macos-${release.arch}.tar.gz";
        hash = release.hash;
        stripRoot = false;
      };

      dontBuild = true;
      dontStrip = true;

      installPhase = ''
        runHook preInstall
        install -Dm755 wb "$out/bin/wb"
        runHook postInstall
      '';

      meta = {
        description = "macOS browser CLI for agents using system WebKit";
        homepage = "https://github.com/aduermael/wb";
        license = lib.licenses.mit;
        mainProgram = "wb";
        platforms = [
          "aarch64-darwin"
          "x86_64-darwin"
        ];
        sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      };
    };

  glimpseui = pkgs.buildNpmPackage (finalAttrs: {
    pname = "glimpseui";
    version = "0.8.1";

    src = pkgs.fetchFromGitHub {
      owner = "hazat";
      repo = "glimpse";
      rev = "v${finalAttrs.version}";
      hash = "sha256-iiOLxg8UnsKPwqNV+zCLFoQZ78pypMr3WkesSf3nkc8=";
    };

    npmDepsHash = "sha256-UoP+RnbNdxBZWQ70c9B5UUWgAifxutz4ySVdAjDOylM=";
    forceEmptyCache = true;
    npmFlags = [ "--ignore-scripts" ];
    npmBuildScript = "build:macos";
    nodejs = unstable.nodejs;

    nativeBuildInputs = [ pkgs.swift ];

    preInstall = ''
      # The package has no npm dependencies, so npm does not create node_modules.
      # npmInstallHook still expects it to exist when copying runtime deps.
      mkdir -p node_modules
    '';

    postInstall = ''
      # Upstream package.json.files excludes the generated native host.
      install -Dm755 src/glimpse "$out/lib/node_modules/glimpseui/src/glimpse"
    '';

    meta = {
      description = "Native micro Web UI for scripts and agents";
      homepage = "https://github.com/hazat/glimpse";
      license = lib.licenses.mit;
      mainProgram = "glimpseui";
      platforms = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    };
  });
}
