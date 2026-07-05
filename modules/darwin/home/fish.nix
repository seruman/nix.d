{
  pkgs,
  serumanDarwin,
  ...
}:

let
  file = relativePath: "${serumanDarwin.filesRoot}/${relativePath}";
in
{
  programs.fish = {
    enable = true;
    package = pkgs.fish;
    # Preserve the old config.fish position: Fish sources conf.d snippets
    # first, then this config body. Keep the body as Fish, not as
    # Nix-translated logic.
    shellInitLast = builtins.readFile (file "fish/config.fish");
  };

  xdg.configFile = {
    "fish/conf.d".source = file "fish/conf.d";
    "fish/functions".source = file "fish/functions";
    "fish/completions".source = file "fish/completions";
    "fish/pkg".source = file "fish/pkg";
  };
}
