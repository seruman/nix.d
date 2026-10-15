{
  fetchurl,
  lib,
  stdenvNoCC,
  undmg,
}:

stdenvNoCC.mkDerivation {
  pname = "sleeve";
  version = "3.3.1";

  src = fetchurl {
    url = "https://replay-sleeve-distribution.s3.amazonaws.com/120/Sleeve.dmg";
    hash = "sha256-VncEqQxTA1ptMPGLVQDUGBul95O0UqXwRPOfR+nHxno=";
  };

  nativeBuildInputs = [ undmg ];
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
}
