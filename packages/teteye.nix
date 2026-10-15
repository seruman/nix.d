{
  fetchurl,
  lib,
  stdenvNoCC,
  unzip,
}:

stdenvNoCC.mkDerivation {
  pname = "teteye";
  version = "nightly-2026-10-06-94a1331";

  src = fetchurl {
    name = "teteye-nightly-2026-10-06-94a1331.zip";
    url = "https://api.github.com/repos/seruman/teteye/releases/assets/615551910";
    hash = "sha256-8OsaWvGhJQ+T+IQt1CwMQPBOaLbVLmAyAS8PwlK1U1c=";
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

  nativeBuildInputs = [ unzip ];
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
}
