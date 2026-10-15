{
  _7zz,
  fetchurl,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "unfolder";
  version = "2.1.0";

  src = fetchurl {
    name = "Unfolder-2.1.0.dmg";
    url = "https://unfolder.app/Unfolder%202.1.0.dmg";
    hash = "sha256-ujkPWsuHLiMapElnSP+Jol1KmFbjxV7l89NNCx+MmsM=";
  };

  nativeBuildInputs = [ _7zz ];
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
}
