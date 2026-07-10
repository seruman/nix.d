{
  lib,
  pkgs,
  pkgsUnstable,
  inputs,
}:

{
  # Use the unwrapped macOS app to preserve upstream Developer ID signing.
  # The wrapped default package replaces Contents/MacOS/glide with a shell
  # wrapper, which invalidates the application bundle signature.
  glide = inputs.glide.packages.${pkgs.stdenv.hostPlatform.system}.glide-browser-bin-unwrapped;

  pi =
    let
      system = pkgs.stdenv.hostPlatform.system;
      release =
        {
          aarch64-darwin = {
            arch = "arm64";
            hash = "sha256-v2HGScRzUVpfC2j7x32kDaHmTQBmJc6i2SbvPPEdPvE=";
          };
        }
        .${system} or (throw "pi is only packaged for aarch64-darwin");
      runtimeBins = lib.makeBinPath [
        pkgsUnstable.bun
        pkgsUnstable.git
        pkgsUnstable.openssh
        pkgsUnstable.ripgrep
        pkgsUnstable.fd
      ];
    in
    pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
      pname = "pi-coding-agent-bin";
      version = "0.80.5";

      src = pkgs.fetchurl {
        url = "https://github.com/earendil-works/pi/releases/download/v${finalAttrs.version}/pi-darwin-${release.arch}.tar.gz";
        hash = release.hash;
      };

      nativeBuildInputs = [ pkgs.makeWrapper ];
      sourceRoot = ".";

      unpackPhase = ''
        runHook preUnpack
        tar -xzf "$src"
        runHook postUnpack
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p "$out/lib" "$out/bin"
        cp -R pi "$out/lib/pi"
        chmod +x "$out/lib/pi/pi"
        makeWrapper "$out/lib/pi/pi" "$out/bin/pi" \
          --set PI_PACKAGE_DIR "$out/lib/pi" \
          --prefix PATH : "${runtimeBins}"
        runHook postInstall
      '';

      meta = {
        description = "Pi terminal coding agent";
        homepage = "https://pi.dev/";
        license = lib.licenses.mit;
        mainProgram = "pi";
        platforms = [ "aarch64-darwin" ];
        sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      };
    });

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
      nodejs = pkgsUnstable.nodejs;
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

  unfolder = pkgs.stdenvNoCC.mkDerivation {
    pname = "unfolder";
    version = "2.1.0";

    src = pkgs.fetchurl {
      name = "Unfolder-2.1.0.dmg";
      url = "https://unfolder.app/Unfolder%202.1.0.dmg";
      hash = "sha256-ujkPWsuHLiMapElnSP+Jol1KmFbjxV7l89NNCx+MmsM=";
    };

    nativeBuildInputs = [ pkgs._7zz ];
    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications"
      cp -R Unfolder.app "$out/Applications/"
      runHook postInstall
    '';

    meta = {
      description = "3D model unfolding tool for creating papercraft";
      homepage = "https://unfolder.app/";
      license = lib.licenses.unfree;
      platforms = [ "aarch64-darwin" ];
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  };

  sleeve = pkgs.stdenvNoCC.mkDerivation {
    pname = "sleeve";
    version = "3.3";

    src = pkgs.fetchurl {
      url = "https://replay-sleeve-distribution.s3.amazonaws.com/latest/Sleeve.dmg";
      hash = "sha256-8Rux0IgKJxj8Gw8wuyoUe/ytRFyhJFJG9Xxu5Xp/B+c=";
    };

    nativeBuildInputs = [ pkgs.undmg ];
    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications"
      cp -R Sleeve.app "$out/Applications/"
      runHook postInstall
    '';

    meta = {
      description = "Music accessory for the Mac";
      homepage = "https://replay.software/sleeve";
      license = lib.licenses.unfree;
      platforms = [ "aarch64-darwin" ];
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  };

  teteye = pkgs.stdenvNoCC.mkDerivation {
    pname = "teteye";
    version = "nightly-2026-07-10-e0349b2";

    src = pkgs.fetchurl {
      name = "teteye-nightly-2026-07-10-e0349b2.zip";
      url = "https://api.github.com/repos/seruman/teteye/releases/assets/472832103";
      hash = "sha256-PiuAvhqqNtFK+SjYK4nK0/c+PeA3yNvvFbRG4J0fSio=";
      curlOptsList = [
        "-H"
        "Accept: application/octet-stream"
        "-H"
        "X-GitHub-Api-Version: 2022-11-28"
      ];
      netrcPhase = ''
        netrc=/etc/nix/teteye-github.netrc
        if [ ! -r "$netrc" ]; then
          echo "missing $netrc; create a fine-grained GitHub token netrc for seruman/teteye" >&2
          exit 1
        fi
        cp "$netrc" netrc
      '';
    };

    nativeBuildInputs = [ pkgs.unzip ];
    sourceRoot = ".";

    unpackPhase = ''
      runHook preUnpack
      unzip -q "$src"
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications"
      cp -R teteye.app "$out/Applications/"
      runHook postInstall
    '';

    meta = {
      description = "Terminal emulator";
      homepage = "https://github.com/seruman/teteye";
      license = lib.licenses.unfree;
      platforms = [ "aarch64-darwin" ];
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  };

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
    nodejs = pkgsUnstable.nodejs;

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
