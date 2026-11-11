{
  container,
  fetchurl,
  makeBinaryWrapper,
}:

container.overrideAttrs (
  finalAttrs: previousAttrs: {
    version = "1.7.1";

    src = fetchurl {
      url = "https://github.com/apple/container/releases/download/${finalAttrs.version}/container-${finalAttrs.version}-installer-signed.pkg";
      hash = "sha256-tnOcrz1HylOnjxp+3zJSFCCnXHlBg4w876dfMLgPWpc=";
    };

    nativeBuildInputs = previousAttrs.nativeBuildInputs ++ [ makeBinaryWrapper ];

    postFixup = (previousAttrs.postFixup or "") + ''
      wrapProgram "$out/bin/container" --set-default CONTAINER_INSTALL_ROOT "$out"
      wrapProgram "$out/bin/container-apiserver" --set-default CONTAINER_INSTALL_ROOT "$out"
    '';
  }
)
