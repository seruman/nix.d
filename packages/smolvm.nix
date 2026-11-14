{
  e2fsprogs,
  fetchurl,
  lib,
  makeWrapper,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "smolvm";
  version = "1.35.0";

  src = fetchurl {
    url = "https://github.com/smol-machines/smolvm/releases/download/v${finalAttrs.version}/smolvm-${finalAttrs.version}-darwin-arm64.tar.gz";
    hash = "sha256-gqojBNyCJKYqrLnPMJ+FHQVMDHzO0Pp7ZTFUFcxNd4g=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/libexec/smolvm" "$out/bin"
    cp -R . "$out/libexec/smolvm/"
    patchShebangs "$out/libexec/smolvm/smolvm"
    makeWrapper "$out/libexec/smolvm/smolvm" "$out/bin/smolvm" \
      --prefix PATH : ${lib.makeBinPath [ e2fsprogs ]}
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME="$TMPDIR/smolvm-home"
    mkdir -p "$HOME"
    "$out/bin/smolvm" --version | grep -Fx "smolvm ${finalAttrs.version}"
    "$out/bin/smolvm" --help > /dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "Branchable microVMs for AI agents";
    homepage = "https://github.com/smol-machines/smolvm";
    license = lib.licenses.asl20;
    mainProgram = "smolvm";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
