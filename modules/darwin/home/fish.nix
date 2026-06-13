{
  config,
  lib,
  pkgs,
  serumanDarwin,
  ...
}:

let
  file = relativePath: "${serumanDarwin.filesRoot}/${relativePath}";
  fishConfig = file "fish/config.fish";
in
{
  programs.fish = {
    enable = true;
    package = pkgs.fish;
    # Preserve the old config.fish position: Fish sources conf.d snippets
    # first, then this config body. Keep the body as Fish, not as
    # Nix-translated logic.
    shellInitLast =
      if serumanDarwin.mutableFiles.enable then
        ''
          source ${lib.escapeShellArg (config.lib.meta.mkMutableTarget fishConfig)}
        ''
      else
        builtins.readFile fishConfig;
  };

  xdg.configFile = {
    "fish/conf.d".source = config.lib.meta.mkConfigSource (file "fish/conf.d");
    "fish/functions".source = config.lib.meta.mkConfigSource (file "fish/functions");
    "fish/completions".source = config.lib.meta.mkConfigSource (file "fish/completions");
    "fish/pkg".source = config.lib.meta.mkConfigSource (file "fish/pkg");
  };
}
