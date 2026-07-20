{ lib, ... }:

{
  imports = [ ./teteye.nix ];

  # Include config.js from within its store directory so its sibling
  # teteye-js-env.d.ts (referenced via `/// <reference path="./..." />`)
  # is copied alongside it; a bare file path would drop the sibling.
  # mkBefore keeps this shared config ahead of any host-specific fragments.
  programs.teteye.configFiles = lib.mkBefore [ "${./files/teteye}/config.js" ];
}
