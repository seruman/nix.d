{
  fetchurl,
  lib,
  stdenvNoCC,
  unzip,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "maccy";
  version = "2.8.0";

  src = fetchurl {
    url = "https://github.com/p0deje/Maccy/releases/download/${finalAttrs.version}/Maccy.app.zip";
    hash = "sha256-5oThzgxg18/9OisYLcN71+iMKZZ6ZKQxoscb5lsdJ+A=";
  };

  nativeBuildInputs = [ unzip ];
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/Applications"
    cp -R Maccy.app "$out/Applications/"
    runHook postInstall
  '';

  meta = {
    description = "Lightweight clipboard manager for macOS";
    homepage = "https://maccy.app/";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
