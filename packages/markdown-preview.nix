{
  _7zz,
  fetchurl,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "markdown-preview";
  version = "0.0.71";
  passthru.buildNumber = 75;

  src = fetchurl {
    url = "https://github.com/pluk-inc/markdown-preview/releases/download/v${finalAttrs.version}/Markdown-Preview.dmg";
    hash = "sha256-rgGSNYDfSsaEiR3mn0e8IYrs9IIj2hdm8ag+2/mir7M=";
  };

  nativeBuildInputs = [ _7zz ];
  sourceRoot = ".";
  postUnpack = ''
    find "Markdown Preview.app" -name '*:com.apple.provenance' -type f -delete
  '';
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/Applications" "$out/bin"
    cp -R "Markdown Preview.app" "$out/Applications/"
    test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' \
      "$out/Applications/Markdown Preview.app/Contents/Info.plist")" = "${toString finalAttrs.passthru.buildNumber}"
    ln -s "$out/Applications/Markdown Preview.app/Contents/Resources/bin/markdown-preview" "$out/bin/mdp"
    runHook postInstall
  '';

  meta = {
    description = "Native Markdown reader with a Quick Look extension";
    homepage = "https://github.com/pluk-inc/markdown-preview";
    license = lib.licenses.mit;
    mainProgram = "mdp";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
