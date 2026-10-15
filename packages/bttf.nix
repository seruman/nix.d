{
  fetchurl,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "bttf";
  version = "0.1.4";

  src = fetchurl {
    url = "https://github.com/BurntSushi/bttf/releases/download/${finalAttrs.version}/bttf-${finalAttrs.version}-aarch64-apple-darwin.tar.gz";
    hash = "sha256-QoQyXgnj4r1i7qdugDcB2BdQYZ+VGVblaY0gjDfJvz8=";
  };

  sourceRoot = "bttf-${finalAttrs.version}-aarch64-apple-darwin";

  installPhase = ''
    runHook preInstall
    install -Dm755 bttf "$out/bin/bttf"
    install -Dm644 README.md "$out/share/doc/bttf/README.md"
    install -Dm644 doc/COMPARISON.md "$out/share/doc/bttf/COMPARISON.md"
    install -Dm644 doc/GUIDE.md "$out/share/doc/bttf/GUIDE.md"
    install -Dm644 LICENSE-MIT "$out/share/licenses/bttf/LICENSE-MIT"
    install -Dm644 UNLICENSE "$out/share/licenses/bttf/UNLICENSE"
    runHook postInstall
  '';

  meta = {
    description = "Command line tool for datetime arithmetic, parsing, formatting and more";
    homepage = "https://github.com/BurntSushi/bttf";
    license = with lib.licenses; [
      mit
      unlicense
    ];
    mainProgram = "bttf";
    platforms = [ "aarch64-darwin" ];
  };
})
