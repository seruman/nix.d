{
  inputs,
  lib,
  pkgs,
  pkgsUnstable,
  ...
}:

let
  derivations = import ./packages/derivations.nix {
    inherit
      inputs
      lib
      pkgs
      pkgsUnstable
      ;
  };
in
{
  environment.systemPackages = [ derivations.teteye ];

  system.activationScripts.postActivation.text = lib.mkAfter ''
    if [ -d "/Applications/Nix Apps/teteye.app" ]; then
      xattr -dr com.apple.quarantine "/Applications/Nix Apps/teteye.app" 2>/dev/null || true
    fi
  '';
}
