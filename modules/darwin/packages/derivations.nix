{
  lib,
  pkgs,
  pkgsUnstable,
  inputs,
}:

let
  agentBrowser =
    assert lib.assertMsg (
      pkgsUnstable.agent-browser.version == "0.27.0"
    ) "terminal-browser requires agent-browser 0.27.0";
    pkgsUnstable.agent-browser;
in
{
  inherit agentBrowser;

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
            hash = "sha256-yZboiLf33ORLzyT2kXasZGxEE505Fr1JprKOWoxeOmU=";
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
      version = "0.84.2";

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

  zigdoc = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "zigdoc";
    version = "0.5.1";

    src = pkgs.fetchurl {
      url = "https://github.com/rockorager/zigdoc/releases/download/v${finalAttrs.version}/zigdoc-v${finalAttrs.version}-macos-arm64.tar.gz";
      hash = "sha256-3xl5img0Q9I8J5y6RMWeXjVPHoc5B8dqb7WM24O+sxw=";
    };

    sourceRoot = "zigdoc-v${finalAttrs.version}-macos-arm64";

    installPhase = ''
      runHook preInstall
      install -Dm755 zigdoc "$out/bin/zigdoc"
      runHook postInstall
    '';

    meta = {
      description = "Command-line tool to view documentation for Zig standard library symbols";
      homepage = "https://github.com/rockorager/zigdoc";
      license = lib.licenses.mit;
      mainProgram = "zigdoc";
      platforms = [ "aarch64-darwin" ];
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  });

  gitHunks = pkgs.stdenvNoCC.mkDerivation {
    pname = "git-hunks";
    version = "1.0.0-unstable-2026-05-13";

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
      version = "0.6.0";

      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/cf/-/cf-${finalAttrs.version}.tgz";
        hash = "sha512-8Fn8HMteKoJEISxmdLBkkF+mnmIwRgYgvGyFbXZTCYYAmEJJDFRs1MAw0NQTxwkn+R3HtZbt1vnoEmeKT7rUEQ==";
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
        description = "Unified command-line interface for Cloudflare";
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
    version = "3.3.1";

    src = pkgs.fetchurl {
      url = "https://replay-sleeve-distribution.s3.amazonaws.com/latest/Sleeve.dmg";
      hash = "sha256-VncEqQxTA1ptMPGLVQDUGBul95O0UqXwRPOfR+nHxno=";
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
    version = "nightly-2026-08-12-d2e5a9b";

    src = pkgs.fetchurl {
      name = "teteye-nightly-2026-08-12-d2e5a9b.zip";
      url = "https://api.github.com/repos/seruman/teteye/releases/assets/512090268";
      hash = "sha256-+8Zu1+FHDzTLLLYBll40XJ3i2T2a32DwD/7lOHLLFp0=";
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

  terminalBrowser = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "terminal-browser-bin";
    version = "0.4.2+seruman.48a0d5cc1468";

    src = pkgs.fetchurl {
      name = "terminal-browser-${finalAttrs.version}-darwin-arm64.tar.gz";
      url = "https://api.github.com/repos/seruman/terminal-browser/releases/assets/504207663";
      hash = "sha256-FeS8EgXPWnvYvKBAGOUrtngMzhM193DzSZtF/hDj54U=";
      curlOptsList = [
        "-H"
        "Accept: application/octet-stream"
        "-H"
        "X-GitHub-Api-Version: 2022-11-28"
      ];
      netrcPhase = ''
        netrc=/etc/nix/terminal-browser-github.netrc
        if [ ! -r "$netrc" ]; then
          echo "missing $netrc; create a fine-grained GitHub token netrc for seruman/terminal-browser" >&2
          exit 1
        fi
        cp "$netrc" netrc
      '';
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];
    sourceRoot = "terminal-browser";
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/terminal-browser" "$out/bin" "$out/share/terminal-browser"
      cp -R . "$out/lib/terminal-browser/"
      install -Dm644 skill/SKILL.md "$out/share/terminal-browser/SKILL.md"
      makeWrapper "$out/lib/terminal-browser/bin/terminal-browser" "$out/bin/terminal-browser" \
        --set TERMINAL_BROWSER_AGENT "${agentBrowser}/bin/agent-browser"
      runHook postInstall
    '';

    passthru = { inherit agentBrowser; };

    meta = {
      description = "Browser rendering in the terminal with agent automation";
      homepage = "https://github.com/seruman/terminal-browser";
      license = lib.licenses.mit;
      mainProgram = "terminal-browser";
      platforms = [ "aarch64-darwin" ];
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
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
