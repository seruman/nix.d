{
  fetchzip,
  lib,
  stdenv,
  stdenvNoCC,
}:

let
  version = "0.1.5";
  system = stdenv.hostPlatform.system;
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
stdenvNoCC.mkDerivation {
  pname = "wb";
  inherit version;

  src = fetchzip {
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
}
