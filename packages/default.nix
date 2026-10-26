{
  pkgs,
  pkgsUnstable,
  inputs,
}:

rec {
  bttf = pkgs.callPackage ./bttf.nix { };
  bun = pkgs.callPackage ./bun.nix {
    inherit (pkgsUnstable) bun;
  };
  claude-code = pkgs.callPackage ./claude-code.nix {
    inherit (pkgsUnstable) claude-code;
  };
  cloudflare-cf = pkgs.callPackage ./cloudflare-cf.nix {
    inherit (pkgsUnstable) nodejs;
  };
  git-hunks = pkgs.callPackage ./git-hunks.nix { };
  glide = pkgs.callPackage ./glide.nix {
    inherit (inputs) glide;
  };
  glimpseui = pkgs.callPackage ./glimpseui.nix {
    inherit (pkgsUnstable) nodejs;
  };
  gridcraft = pkgs.callPackage ./gridcraft.nix { };
  ollama = pkgs.callPackage ./ollama.nix { };
  pi = pkgs.callPackage ./pi.nix {
    inherit bun;
    inherit (pkgsUnstable)
      fd
      git
      openssh
      ripgrep
      ;
  };
  rex-terminfo = pkgs.callPackage ./rex-terminfo { };
  sleeve = pkgs.callPackage ./sleeve.nix { };
  teteye = pkgs.callPackage ./teteye.nix { };
  unfolder = pkgs.callPackage ./unfolder.nix { };
  wb = pkgs.callPackage ./wb.nix { };
  zigdoc = pkgs.callPackage ./zigdoc.nix { };
}
