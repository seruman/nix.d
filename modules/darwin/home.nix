{
  config,
  inputs,
  lib,
  pkgs,
  serumanDarwin,
  unstable,
  ...
}:

let
  file = relativePath: "${serumanDarwin.filesRoot}/${relativePath}";

  mutableTarget =
    path:
    serumanDarwin.configPath + lib.removePrefix (toString serumanDarwin.sourceRoot) (toString path);

  configSource =
    path:
    if serumanDarwin.mutableFiles.enable then
      config.lib.file.mkOutOfStoreSymlink (mutableTarget path)
    else
      path;
in
{
  imports = [
    inputs.opnix.homeManagerModules.default
    inputs.pi.homeModules.default
    ./home/fish.nix
    ./home/git.nix
    ./home/ghostty.nix
    ./home/ssh.nix
  ];

  home.username = serumanDarwin.username;
  home.homeDirectory = serumanDarwin.homeDirectory;

  lib.meta = {
    inherit (serumanDarwin) configPath filesRoot sourceRoot;
    mkConfigSource = configSource;
    mkMutableTarget = mutableTarget;
  };

  # Keep this fixed after the first Home Manager activation.
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  programs.man.generateCaches = false;

  programs.pi.coding-agent.enable = true;

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
    BUN_INSTALL = "${config.home.homeDirectory}/.bun";
    LIGHTPANDA_DISABLE_TELEMETRY = "true";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/go/bin"
    "${config.home.homeDirectory}/.cargo/bin"
    "${config.home.homeDirectory}/.bun/bin"
    "${config.home.homeDirectory}/bin"
    "${config.home.homeDirectory}/sbin"
  ];

  home.activation.xdgRuntimeDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg "${config.home.homeDirectory}/.xdg"}
    run chmod 700 ${lib.escapeShellArg "${config.home.homeDirectory}/.xdg"}
  '';

  home.activation.glideWorkConfigSymlink = lib.mkIf serumanDarwin.mutableFiles.enable (
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      glide_work_link=${lib.escapeShellArg (mutableTarget (file "glide/glide.work.ts"))}
      glide_work_target=${lib.escapeShellArg "${config.xdg.configHome}/work/glide/glide.ts"}

      if [ -e "$glide_work_link" ] && [ ! -L "$glide_work_link" ]; then
        echo "not replacing non-symlink $glide_work_link" >&2
      else
        run ln -sfn "$glide_work_target" "$glide_work_link"
      fi
    ''
  );

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
    package = unstable.fzf;
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
    package = unstable.zoxide;
    enableFishIntegration = true;
    options = [
      "--cmd"
      "j"
    ];
  };

  programs.direnv = {
    enable = true;
    package = unstable.direnv;
    enableFishIntegration = true;
    stdlib = lib.mkBefore (builtins.readFile (file "direnv/direnvrc"));
  };

  programs.bat = {
    enable = true;
    package = unstable.bat;
    config.theme = "seruzen";
    themes.seruzen = {
      src = file "bat/themes";
      file = "seruzen.tmTheme";
    };
  };

  programs.fd = {
    enable = true;
    package = unstable.fd;
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
    package = unstable.ripgrep;
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
    package = unstable.tmux;
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
        plugin = unstable.tmuxPlugins.prefix-highlight;
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
    '';

    ".bunfig.toml".text = ''
      [install]
      # Only install package versions published at least 7 days ago.
      minimumReleaseAge = 604800
    '';

    ".pi/agent/settings.json" = {
      source = config.lib.meta.mkConfigSource (file "pi/agent/settings.json");
      force = true;
    };

    ".pi/agent/APPEND_SYSTEM.md" = {
      source = config.lib.meta.mkConfigSource (file "pi/agent/APPEND_SYSTEM.md");
      force = true;
    };

    "bin/git-histcopy".source = config.lib.meta.mkConfigSource (file "bin/git-histcopy");
    "bin/pils".source = config.lib.meta.mkConfigSource (file "bin/pils");
    "bin/tmux-cssh".source = config.lib.meta.mkConfigSource (file "bin/tmux-cssh");
  };

  xdg.configFile = {
    "uv/uv.toml".text = ''
      # Only install package versions published at least 7 days ago.
      exclude-newer = "7 days"
    '';

    "nvim".source = config.lib.meta.mkConfigSource (file "nvim");

    "glide/biome.json".source = config.lib.meta.mkConfigSource (file "glide/biome.json");
    "glide/commands.glide.ts".source = config.lib.meta.mkConfigSource (file "glide/commands.glide.ts");
    "glide/github.glide.ts".source = config.lib.meta.mkConfigSource (file "glide/github.glide.ts");
    "glide/glide.ts".source = config.lib.meta.mkConfigSource (file "glide/glide.ts");
    "glide/package.json".source = config.lib.meta.mkConfigSource (file "glide/package.json");
    "glide/tsconfig.json".source = config.lib.meta.mkConfigSource (file "glide/tsconfig.json");
    "glide/ui.glide.ts".source = config.lib.meta.mkConfigSource (file "glide/ui.glide.ts");
    "teteye".source = config.lib.meta.mkConfigSource (file "teteye");
  };

}
