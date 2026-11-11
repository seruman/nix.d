{
  fetchurl,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mocker";
  version = "nightly-2026-11-11-c99e73f";

  src = fetchurl {
    url = "https://github.com/seruman/mocker/releases/download/${finalAttrs.version}/mocker.tar.gz";
    hash = "sha256-nZOXuboOCPcc1dUOaYqariEPpPHgq/q+aQ3SXLDAZpk=";
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 mocker "$out/bin/mocker"
    runHook postInstall
  '';

  meta = {
    description = "Docker-compatible CLI built on Apple's Containerization framework";
    homepage = "https://github.com/seruman/mocker";
    license = lib.licenses.agpl3Only;
    mainProgram = "mocker";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
