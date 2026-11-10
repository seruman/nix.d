{
  claude-code,
  fetchurl,
  lib,
  stdenv,
}:

claude-code.overrideAttrs (
  finalAttrs: oldAttrs: {
    version = "2.1.321";
    src =
      assert stdenv.hostPlatform.system == "aarch64-darwin";
      fetchurl {
        url = "https://downloads.claude.ai/claude-code-releases/${finalAttrs.version}/darwin-arm64/claude";
        sha256 = "abc9feeeca8091d51b623291e044cf0528c2f6b74e0c1d6ef671d52c73f7cd3c";
      };

    installPhase =
      assert lib.hasInfix "unzstd -q $src -o $out/bin/claude" oldAttrs.installPhase;
      lib.replaceString "unzstd -q $src -o $out/bin/claude" "cp $src $out/bin/claude"
        oldAttrs.installPhase;

    postInstall = (oldAttrs.postInstall or "") + ''
      wrapProgram "$out/bin/claude" \
        --set DISABLE_TELEMETRY 1 \
        --set DISABLE_ERROR_REPORTING 1 \
        --set-default NODE_EXTRA_CA_CERTS /etc/ssl/certs/ca-certificates.crt
    '';
  }
)
