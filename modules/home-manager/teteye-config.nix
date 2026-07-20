{ lib, ... }:

{
  imports = [ ./teteye.nix ];

  # Shared teteye configuration layered ahead of any host-specific fragments.
  # Hosts can append their own files via `programs.teteye.configFiles` (mkAfter).
  programs.teteye.configFiles = lib.mkBefore [ ./files/teteye/config.js ];
}
