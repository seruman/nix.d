{
  agent-browser,
  fetchurl,
  lib,
  makeWrapper,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "terminal-browser-bin";
  version = "0.4.2+seruman.48a0d5cc1468";

  src = fetchurl {
    name = "terminal-browser-${finalAttrs.version}-darwin-arm64.tar.gz";
    url = "https://api.github.com/repos/seruman/terminal-browser/releases/assets/504207663";
    hash = "sha256-FeS8EgXPWnvYvKBAGOUrtngMzhM193DzSZtF/hDj54U=";
    curlOptsList = [
      "-H"
      "Accept: application/octet-stream"
      "-H"
      "X-GitHub-Api-Version: 2022-11-28"
    ];
    netrcPhase = ''
      netrc=/etc/nix/terminal-browser-github.netrc
      if [ ! -r "$netrc" ]; then
        echo "missing $netrc; create a fine-grained GitHub token netrc for seruman/terminal-browser" >&2
        exit 1
      fi
      cp "$netrc" netrc
    '';
  };

  nativeBuildInputs = [ makeWrapper ];
  sourceRoot = "terminal-browser";
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/terminal-browser" "$out/bin" "$out/share/terminal-browser"
    cp -R . "$out/lib/terminal-browser/"
    install -Dm644 skill/SKILL.md "$out/share/terminal-browser/SKILL.md"
    makeWrapper "$out/lib/terminal-browser/bin/terminal-browser" "$out/bin/terminal-browser" \
      --set TERMINAL_BROWSER_AGENT "${agent-browser}/bin/agent-browser"
    runHook postInstall
  '';

  passthru = { inherit agent-browser; };

  meta = {
    description = "Browser rendering in the terminal with agent automation";
    homepage = "https://github.com/seruman/terminal-browser";
    license = lib.licenses.mit;
    mainProgram = "terminal-browser";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
