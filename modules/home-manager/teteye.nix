{ config, lib, ... }:

let
  cfg = config.programs.teteye;

  generatedConfig = lib.concatMapStrings (
    file: "teteye.include(${builtins.toJSON file});\n"
  ) cfg.configFiles;
in
{
  options.programs.teteye = {
    enable = lib.mkEnableOption "Teteye configuration";

    configFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = ''
        Ordered JavaScript configuration files included by the generated root config.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."teteye/config.js".text = generatedConfig;
  };
}
