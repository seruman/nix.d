{
  pname,
  version,
  description,
  dmgHash,
  cliHash,
}:
{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  _7zz,
  unzip,
}:

let
  fetch =
    name: hash:
    fetchurl {
      url = "https://github.com/storytold/${pname}/releases/download/v${version}/${name}";
      inherit hash;
    };
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  srcs = [
    (fetch "${pname}-${version}-macos-universal.dmg" dmgHash)
    (fetch "${pname}-cli-${version}-macos-universal.zip" cliHash)
  ];

  sourceRoot = ".";
  nativeBuildInputs = [
    makeWrapper
    _7zz
    unzip
  ];
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/Applications" "$out/bin"
    cp -R */*.app "$out/Applications/"
    cp ${pname}-cli-*/${pname}-cli "$out/bin/"
    makeWrapper "$out"/Applications/*.app/Contents/MacOS/* "$out/bin/${pname}"
    runHook postInstall
  '';

  meta = {
    inherit description;
    homepage = "https://getartcraft.com/apps/${pname}";
    changelog = "https://github.com/storytold/${pname}/releases/tag/v${version}";
    license = with lib.licenses; [
      mit
      asl20
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = pname;
    platforms = lib.platforms.darwin;
  };
}
