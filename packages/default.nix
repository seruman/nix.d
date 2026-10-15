{
  pkgs,
  pkgsUnstable,
  inputs,
}:

rec {
  agent-browser = pkgs.callPackage ./agent-browser.nix {
    inherit (pkgsUnstable) agent-browser;
  };
  bttf = pkgs.callPackage ./bttf.nix { };
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
    inherit (pkgsUnstable)
      bun
      fd
      git
      openssh
      ripgrep
      ;
  };
  rex-terminfo = pkgs.callPackage ./rex-terminfo { };
  sleeve = pkgs.callPackage ./sleeve.nix { };
  terminal-browser = pkgs.callPackage ./terminal-browser.nix {
    inherit agent-browser;
  };
  teteye = pkgs.callPackage ./teteye.nix { };
  unfolder = pkgs.callPackage ./unfolder.nix { };
  wb = pkgs.callPackage ./wb.nix { };
  zigdoc = pkgs.callPackage ./zigdoc.nix { };
}
