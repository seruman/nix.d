{
  config,
  inputs,
  lib,
  pkgs,
  serumanDarwin,
  turkishKeyboardLayout,
  pkgsUnstable,
  ...
}:

let
  file = relativePath: "${serumanDarwin.filesRoot}/${relativePath}";

  derivations = import ./packages/derivations.nix {
    inherit
      inputs
      lib
      pkgs
      pkgsUnstable
      ;
  };
  inherit (derivations)
    bttf
    cloudflareCf
    gitHunks
    glimpseui
    pi
    wb
    ;
in
{
  imports = [
    inputs.opnix.homeManagerModules.default
    ./home/fish.nix
    ./home/git.nix
    ./home/ghostty.nix
    ./home/ssh.nix
    ./home/teteye.nix
  ];

  home.username = serumanDarwin.username;
  home.homeDirectory = serumanDarwin.homeDirectory;

  # Keep this fixed after the first Home Manager activation.
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  programs.man.generateCaches = false;

  # Skip the home-configuration-reference-manpage. It runs nixosOptionsDoc and
  # bakes nixpkgs source store paths into options.json without context, which
  # is what produces the "references the store path ... without a proper
  # context" warning on every build. Not used.
  manual.manpages.enable = false;

  xdg = {
    enable = true;
    localBinInPath = true;
  };

  # Home Manager manages the standard XDG variables via `xdg.enable`; it
  # does not define XDG_RUNTIME_DIR, so keep the location here instead of
  # in Fish startup code.
  home.sessionVariables = {
    XDG_RUNTIME_DIR = "${config.home.homeDirectory}/.xdg";
    EDITOR = "nvim";
    PAGER = "less";
    LESS = "-R --mouse";
    LIGHTPANDA_DISABLE_TELEMETRY = "true";
    OP_BIOMETRIC_UNLOCK_ENABLED = "true";
    WB_UPDATE_CHECK = "off";
    WB_NO_UPDATE_CHECK = "1";
    WB_SKILL_AUTO_UPDATE = "off";
    WB_NO_SKILL_AUTO_UPDATE = "1";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/go/bin"
    "${config.home.homeDirectory}/.cargo/bin"
    "${config.home.homeDirectory}/bin"
    "${config.home.homeDirectory}/sbin"
  ];

  home.packages = [
    pkgsUnstable._1password-cli
    pkgsUnstable.claude-code
    pi

    bttf
    pkgsUnstable.biome
    pkgsUnstable.bun
    pkgsUnstable.go
    pkgsUnstable.lua
    pkgsUnstable.luarocks
    pkgsUnstable.neovim
    pkgsUnstable.nodejs
    pkgsUnstable.openssh
    pkgsUnstable.python3
    pkgsUnstable.rustup
    pkgsUnstable.uv
    pkgsUnstable.wasmer
    pkgsUnstable.wasmtime
    pkgsUnstable.zig

    pkgsUnstable.deadnix
    pkgsUnstable.nix-diff
    pkgsUnstable.nix-output-monitor
    pkgsUnstable.nix-tree
    pkgsUnstable.nvd
    pkgsUnstable.statix

    pkgsUnstable.git
    pkgsUnstable.as-tree
    pkgsUnstable.chafa
    pkgsUnstable.colordiff
    pkgsUnstable.curl
    pkgsUnstable.diff-so-fancy
    pkgsUnstable.difftastic
    pkgsUnstable.duckdb
    pkgsUnstable.ffmpeg
    pkgsUnstable.gh
    pkgsUnstable.ghq
    pkgsUnstable.agent-browser
    pkgsUnstable.cloudflared
    cloudflareCf
    gitHunks
    wb
    glimpseui
    pkgsUnstable.git-filter-repo
    pkgsUnstable.glow
    pkgsUnstable.gnumake
    pkgsUnstable.gojq
    pkgsUnstable.gofumpt
    pkgsUnstable.gopls
    pkgsUnstable.gotest
    pkgsUnstable.gotestsum
    pkgsUnstable.gotools
    pkgsUnstable.gum
    pkgsUnstable.htop
    pkgsUnstable.httpie
    pkgsUnstable.hyperfine
    pkgsUnstable.jq
    pkgsUnstable.just
    pkgsUnstable.less
    pkgsUnstable.massren
    pkgsUnstable.mergiraf
    pkgsUnstable.mpv
    pkgsUnstable.rsync
    pkgsUnstable.ruff
    pkgsUnstable.sad
    pkgsUnstable.tree
    pkgsUnstable.watch
    pkgsUnstable.yq

    pkgsUnstable.docker-client
    pkgsUnstable.docker-buildx
    pkgsUnstable.docker-compose

    pkgsUnstable.bash-language-server
    pkgsUnstable.clang-tools
    pkgsUnstable.csharpier
    pkgsUnstable.fish-lsp
    pkgsUnstable.fishPlugins.forgit
    pkgsUnstable.lua-language-server
    pkgsUnstable.nixd
    pkgsUnstable.nixfmt
    pkgsUnstable.protobuf-language-server
    pkgsUnstable.roslyn-ls
    pkgsUnstable.shellcheck
    pkgsUnstable.shfmt
    pkgsUnstable.sourcekit-lsp
    pkgsUnstable.stylua
    pkgsUnstable.tailwindcss-language-server
    pkgsUnstable.tree-sitter
    pkgsUnstable.taplo
    pkgsUnstable.terraform-ls
    pkgsUnstable.typos-lsp
    pkgsUnstable.typescript-language-server
    pkgsUnstable.yaml-language-server
    pkgsUnstable.zls
  ];

  home.activation.xdgRuntimeDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg "${config.home.homeDirectory}/.xdg"}
    run chmod 700 ${lib.escapeShellArg "${config.home.homeDirectory}/.xdg"}
  '';

  services.macos-remap-keys = {
    enable = true;
    keyboard.Capslock = "Control";
  };

  programs.onepassword-secrets = {
    enable = true;
    tokenFile = "${config.xdg.configHome}/opnix/token";
    secrets.braveSearchApiKey = {
      reference = "op://nix/brave-api-key/credential";
      path = ".config/opnix/secrets/brave-search-api-key";
      mode = "0600";
    };
  };

  programs.fzf = {
    enable = true;
    package = pkgsUnstable.fzf;
    enableFishIntegration = true;
    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--inline-info"
      "--border"
    ];
  };

  programs.zoxide = {
    enable = true;
    package = pkgsUnstable.zoxide;
    enableFishIntegration = true;
    options = [
      "--cmd"
      "j"
    ];
  };

  programs.direnv = {
    enable = true;
    package = pkgsUnstable.direnv;
    enableFishIntegration = true;
    stdlib = lib.mkBefore (builtins.readFile (file "direnv/direnvrc"));
  };

  programs.bat = {
    enable = true;
    package = pkgsUnstable.bat;
    config.theme = "seruzen";
    themes.seruzen = {
      src = file "bat/themes";
      file = "seruzen.tmTheme";
    };
  };

  programs.fd = {
    enable = true;
    package = pkgsUnstable.fd;
    ignores = [
      ".direnv/"
      "vendor/"
      "!.github/"
      ".venv/"
      "envrc/"
      "__pycache__/"
      "node_modules/"
    ];
  };

  programs.ripgrep = {
    enable = true;
    package = pkgsUnstable.ripgrep;
    arguments = [
      "--hidden"
      "--glob=!.git/"
      "--glob=!{.direnv/,vendor/}"
      "--glob=!{**/.direnv/,**/vendor/}"
      "--glob=!.ropeproject/"
      "--glob=!.venv/"
      "--glob=!.envrc/"
      "--glob=!vendor/"
      "--glob=!__pycache__/"
      "--glob=!node_modules/"
    ];
  };

  programs.tmux = {
    enable = true;
    package = pkgsUnstable.tmux;
    baseIndex = 1;
    escapeTime = 0;
    focusEvents = true;
    historyLimit = 10000;
    keyMode = "vi";
    mouse = true;
    terminal = "tmux-256color";
    extraConfig = builtins.readFile (file "tmux/tmux.conf");
    plugins = [
      {
        plugin = pkgsUnstable.tmuxPlugins.prefix-highlight;
        extraConfig = ''
          set -g @prefix_highlight_show_copy_mode 'on'
          set -g @prefix_highlight_show_sync_mode 'on'
          set -g @prefix_highlight_prefix_prompt 'Wait'
          set -g @prefix_highlight_copy_prompt 'Copy'
          set -g @prefix_highlight_sync_prompt 'Sync'
        '';
      }
    ];
  };

  home.file = {
    ".npmrc".text = ''
      # Only install package versions published at least 7 days ago.
      min-release-age=7
      # Supply-chain hardening: never run install lifecycle scripts.
      # Re-enable per-project with `npm install --ignore-scripts=false`.
      ignore-scripts=true
    '';

    ".bunfig.toml".text = ''
      [install]
      # Only install package versions published at least 7 days ago.
      minimumReleaseAge = 604800
      # Supply-chain hardening: disable lifecycle scripts for all packages,
      # including Bun's built-in trusted-dependencies allow-list. Re-enable
      # per-project via `trustedDependencies` in that package.json.
      ignoreScripts = true
    '';

    # Yarn Berry (v2+): block dependency build scripts globally.
    ".yarnrc.yml".text = ''
      enableScripts: false
    '';

    # Yarn Classic (v1): block lifecycle scripts globally.
    ".yarnrc".text = ''
      ignore-scripts true
    '';

    "Library/Keyboard Layouts/TurkishQLegacyFixed.keylayout" = {
      source = "${turkishKeyboardLayout}/TurkishQLegacyFixed.keylayout";
      force = true;
    };

    ".pi/agent/settings.json" = {
      source = file "pi/agent/settings.json";
      force = true;
    };

    ".pi/agent/APPEND_SYSTEM.md" = {
      source = file "pi/agent/APPEND_SYSTEM.md";
      force = true;
    };

    "bin/git-histcopy".source = file "bin/git-histcopy";
    "bin/pils".source = file "bin/pils";
    "bin/tmux-cssh".source = file "bin/tmux-cssh";
  };

  xdg.configFile = {
    "uv/uv.toml".text = ''
      # Only install package versions published at least 7 days ago.
      exclude-newer = "7 days"
    '';

    "nvim".source = file "nvim";

    "glide/biome.json".source = file "glide/biome.json";
    "glide/commands.glide.ts".source = file "glide/commands.glide.ts";
    "glide/github.glide.ts".source = file "glide/github.glide.ts";
    "glide/glide.ts".source = file "glide/glide.ts";
    "glide/package.json".source = file "glide/package.json";
    "glide/tsconfig.json".source = file "glide/tsconfig.json";
    "glide/ui.glide.ts".source = file "glide/ui.glide.ts";
  };

}
