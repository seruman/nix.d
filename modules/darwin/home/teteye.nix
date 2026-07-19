{ ... }:

{
  imports = [ ../../home-manager/teteye.nix ];

  programs.teteye.configFiles = [ ../files/teteye/config.js ];
}
