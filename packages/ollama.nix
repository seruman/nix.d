{
  fetchurl,
  lib,
  stdenv,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "ollama-mlx-bin";
  version = "0.40.0";

  src =
    assert stdenv.hostPlatform.system == "aarch64-darwin";
    fetchurl {
      url = "https://github.com/ollama/ollama/releases/download/v${finalAttrs.version}/ollama-darwin.tgz";
      hash = "sha256-tJC0klqVxfPfzYieVmzz3NcnhI1ZBX+wCwPx1mMDJtw=";
    };

  dontUnpack = true;
  dontBuild = true;
  # Preserve upstream signatures and relative dylib/Metal asset lookup.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/ollama" "$out/bin"
    tar -xzf "$src" -C "$out/lib/ollama"
    ln -s "$out/lib/ollama/ollama" "$out/bin/ollama"
    test -x "$out/bin/ollama"
    test -x "$out/lib/ollama/llama-server"
    for backend in mlx_metal_v3 mlx_metal_v4; do
      test -s "$out/lib/ollama/$backend/libmlx.dylib"
      test -s "$out/lib/ollama/$backend/libmlxc.dylib"
      test -s "$out/lib/ollama/$backend/mlx.metallib"
    done
    runHook postInstall
  '';

  meta = {
    description = "Official Ollama macOS distribution with precompiled MLX backends";
    homepage = "https://ollama.com";
    license = lib.licenses.mit;
    mainProgram = "ollama";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
