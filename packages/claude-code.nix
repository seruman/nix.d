{
  claude-code,
  fetchurl,
  stdenv,
}:

claude-code.overrideAttrs (
  finalAttrs: oldAttrs: {
    version = "2.1.267";
    src =
      assert stdenv.hostPlatform.system == "aarch64-darwin";
      fetchurl {
        url = "https://downloads.claude.ai/claude-code-releases/${finalAttrs.version}/darwin-arm64/claude";
        sha256 = "a681f3008f0050029aeebcab3af51bb6a55ddeb625a3af3141a4416d43cd2558";
      };

    postInstall = (oldAttrs.postInstall or "") + ''
      wrapProgram "$out/bin/claude" \
        --set DISABLE_TELEMETRY 1 \
        --set DISABLE_ERROR_REPORTING 1
    '';
  }
)
