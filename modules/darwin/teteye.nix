{
  lib,
  localPackages,
  ...
}:

{
  environment.systemPackages = [ localPackages.teteye ];

  system.activationScripts.postActivation.text = lib.mkAfter ''
    if [ -d "/Applications/Nix Apps/teteye.app" ]; then
      xattr -dr com.apple.quarantine "/Applications/Nix Apps/teteye.app" 2>/dev/null || true
    fi
  '';
}
