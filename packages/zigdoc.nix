{
  fetchurl,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "zigdoc";
  version = "0.5.1";

  src = fetchurl {
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
})
