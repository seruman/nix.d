{
  fetchurl,
  lib,
  makeWrapper,
  nodejs,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "cloudflare-cf";
  version = "0.6.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/cf/-/cf-${finalAttrs.version}.tgz";
    hash = "sha512-8Fn8HMteKoJEISxmdLBkkF+mnmIwRgYgvGyFbXZTCYYAmEJJDFRs1MAw0NQTxwkn+R3HtZbt1vnoEmeKT7rUEQ==";
  };

  sourceRoot = "package";
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/cloudflare-cf" "$out/bin"
    cp -R bin dist package.json README.md "$out/lib/cloudflare-cf/"
    chmod +x "$out/lib/cloudflare-cf/bin/cf"
    makeWrapper ${nodejs}/bin/node "$out/bin/cf" \
      --add-flags "$out/lib/cloudflare-cf/bin/cf"
    runHook postInstall
  '';

  meta = {
    description = "Unified command-line interface for Cloudflare";
    homepage = "https://blog.cloudflare.com/cf-cli-local-explorer/";
    license = lib.licenses.mit;
    mainProgram = "cf";
  };
})
