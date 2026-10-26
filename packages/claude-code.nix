{
  claude-code,
  fetchurl,
  lib,
  stdenv,
}:

claude-code.overrideAttrs (
  finalAttrs: oldAttrs: {
    version = "2.1.310";
    src =
      assert stdenv.hostPlatform.system == "aarch64-darwin";
      fetchurl {
        url = "https://downloads.claude.ai/claude-code-releases/${finalAttrs.version}/darwin-arm64/claude";
        sha256 = "ffb64331bc0ee1b69efb7c2c428bd3ab516bc31b75bf60886b356c97c1c25ffd";
      };

    installPhase =
      assert lib.hasInfix "unzstd -q $src -o $out/bin/claude" oldAttrs.installPhase;
      lib.replaceString "unzstd -q $src -o $out/bin/claude" "cp $src $out/bin/claude"
        oldAttrs.installPhase;

    postInstall = (oldAttrs.postInstall or "") + ''
      wrapProgram "$out/bin/claude" \
        --set DISABLE_TELEMETRY 1 \
        --set DISABLE_ERROR_REPORTING 1
    '';
  }
)
