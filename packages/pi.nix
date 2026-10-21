{
  bun,
  fd,
  fetchurl,
  git,
  jq,
  lib,
  makeWrapper,
  openssh,
  ripgrep,
  runCommand,
  stdenv,
  stdenvNoCC,
  caBundle ? "/etc/ssl/certs/ca-certificates.crt",
}:

let
  system = stdenv.hostPlatform.system;
  release =
    {
      aarch64-darwin = {
        arch = "arm64";
        hash = "sha256-H5rmHN6uBN1oyvGh6KuOybKSBi9syzJS4KnL6TtbFvE=";
      };
    }
    .${system} or (throw "pi is only packaged for aarch64-darwin");
  runtimeBins = lib.makeBinPath [
    bun
    git
    openssh
    ripgrep
    fd
  ];
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "pi-coding-agent-bin";
  version = "1.3.0";

  src = fetchurl {
    url = "https://github.com/earendil-works/pi/releases/download/v${finalAttrs.version}/pi-darwin-${release.arch}.tar.gz";
    hash = release.hash;
  };

  nativeBuildInputs = [ makeWrapper ];
  sourceRoot = ".";

  # Pi takes its name, banner and config env var names from `piConfig.name` in
  # the package.json it finds in PI_PACKAGE_DIR.
  passthru.rebrand =
    {
      name,
      envDefaults ? { },
    }:
    let
      packageDir =
        runCommand "${name}-package-dir-${finalAttrs.version}" { nativeBuildInputs = [ jq ]; }
          ''
            mkdir -p "$out"
            for entry in ${finalAttrs.finalPackage}/lib/pi/*; do
              entryName=$(basename "$entry")
              [ "$entryName" = package.json ] || ln -s "$entry" "$out/$entryName"
            done
            jq --arg name ${lib.escapeShellArg name} '.piConfig.name = $name' \
              ${finalAttrs.finalPackage}/lib/pi/package.json > "$out/package.json"
          '';

      envArgs = lib.concatStringsSep " \\\n    " (
        lib.mapAttrsToList (
          key: value: "--set-default ${lib.escapeShellArg key} ${lib.escapeShellArg (toString value)}"
        ) envDefaults
      );

      agentDirVar = "${lib.toUpper name}_CODING_AGENT_DIR";
    in
    runCommand "${name}-${finalAttrs.version}"
      {
        nativeBuildInputs = [ makeWrapper ];
        meta = finalAttrs.meta // {
          description = "${finalAttrs.meta.description}, rebranded as ${name}";
          mainProgram = name;
        };
      }
      ''
        # https://emudhra.we-have-a-problem.com/
        makeWrapper ${packageDir}/pi "$out/bin/${name}" \
          --set SSL_CERT_FILE ${lib.escapeShellArg caBundle} \
          --set PI_PACKAGE_DIR "${packageDir}" \
          --set-default PI_SKIP_VERSION_CHECK 1 \
          --set-default PI_TELEMETRY 0 \
          ${envArgs} \
          --prefix PATH : "${runtimeBins}"

        if ! "$out/bin/${name}" --help | grep -q ${agentDirVar}; then
          echo "pi ${finalAttrs.version} does not honour piConfig.name" >&2
          exit 1
        fi
      '';

  unpackPhase = ''
    runHook preUnpack
    tar -xzf "$src"
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib" "$out/bin"
    cp -R pi "$out/lib/pi"
    chmod +x "$out/lib/pi/pi"
    # https://emudhra.we-have-a-problem.com/
    makeWrapper "$out/lib/pi/pi" "$out/bin/pi" \
      --set SSL_CERT_FILE ${lib.escapeShellArg caBundle} \
      --set PI_PACKAGE_DIR "$out/lib/pi" \
      --set-default PI_SKIP_VERSION_CHECK 1 \
      --set-default PI_TELEMETRY 0 \
      --prefix PATH : "${runtimeBins}"
    runHook postInstall
  '';

  meta = {
    description = "Pi terminal coding agent";
    homepage = "https://pi.dev/";
    license = lib.licenses.mit;
    mainProgram = "pi";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
