{
  bun,
  lib,
  makeWrapper,
  symlinkJoin,
  caBundle ? "/etc/ssl/certs/ca-certificates.crt",
}:

symlinkJoin {
  inherit (bun)
    name
    pname
    version
    meta
    ;
  paths = [ bun ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    # https://emudhra.we-have-a-problem.com/
    wrapProgram "$out/bin/bun" --set SSL_CERT_FILE ${lib.escapeShellArg caBundle}
    ln -sfn bun "$out/bin/bunx"
  '';
}
