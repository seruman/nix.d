{
  container,
  fetchurl,
}:

container.overrideAttrs (
  finalAttrs: _: {
    version = "1.7.1";

    src = fetchurl {
      url = "https://github.com/apple/container/releases/download/${finalAttrs.version}/container-${finalAttrs.version}-installer-signed.pkg";
      hash = "sha256-tnOcrz1HylOnjxp+3zJSFCCnXHlBg4w876dfMLgPWpc=";
    };
  }
)
