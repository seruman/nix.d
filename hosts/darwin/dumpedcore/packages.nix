{
  inputs,
  lib,
  pkgs,
  pkgsUnstable,
  username,
  ...
}:

let
  derivations = import ../../../modules/darwin/packages/derivations.nix {
    inherit
      inputs
      lib
      pkgs
      pkgsUnstable
      ;
  };
in
{
  environment.systemPackages = [ derivations.unfolder ];

  home-manager.users.${username}.home.packages = [
    pkgsUnstable.yt-dlp
  ];
}
