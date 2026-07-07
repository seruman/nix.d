{
  lib,
  pkgs,
  pkgsUnstable,
  inputs,
  ...
}:

let
  derivations = import ./derivations.nix {
    inherit
      lib
      pkgs
      pkgsUnstable
      inputs
      ;
  };
in
{
  programs._1password = {
    enable = true;
    package = pkgsUnstable._1password-cli;
  };

  environment.systemPackages = [
    derivations.glide
    derivations.sleeve
  ];

  environment.shells = [ pkgs.fish ];
  programs.fish.enable = true;
}
