{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  mbx = inputs.mbx.packages.${pkgs.stdenv.hostPlatform.system}.mbx;
in
{
  home.packages = [ mbx ];

  # Use upstream's opt-in Cargo wrapper, ahead of the existing Rust toolchain.
  home.sessionPath = lib.mkBefore [ "${mbx}/libexec/mbx" ];

  # mbx uses the native macOS config directory, not XDG_CONFIG_HOME.
  home.file."Library/Application Support/mbx/config.toml".text = ''
    [gc]
    # Preview with `mbx gc --dry-run` before enabling automatic collection.
    auto = false
    max_total_size = "150GiB"
  '';
}
