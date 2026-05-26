{ config, inputs, lib, pkgs, ... }:

let
  username = "selman";
  homeDirectory = "/Users/${username}";
  screenshotsDirectory = "${homeDirectory}/etc/screenshots";

  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };

  glide = inputs.glide.packages.${pkgs.stdenv.hostPlatform.system}.default;

  turkishKeyboardLayout = pkgs.fetchFromGitHub {
    owner = "seruman";
    repo = "macos-turkish-keyboard-layout";
    rev = "1d87f298c8e665c8d48fcc184bf364f96d3a1b68";
    hash = "sha256-O0Fn7TtTaj3Puf4CvN0DYDY+hcwb5vJ2D25HXlzayMY=";
  };

  localHomebrewTap = pkgs.runCommand "homebrew-seruman-local-tap" { nativeBuildInputs = [ pkgs.git ]; } ''
    mkdir -p "$out/Casks"
    cp ${./homebrew-casks/1password.rb} "$out/Casks/1password.rb"

    git -C "$out" init -q
    git -C "$out" config user.email nix@example.invalid
    git -C "$out" config user.name nix
    git -C "$out" add Casks/1password.rb
    git -C "$out" commit -q -m init
  '';

  xdgEnvironment = {
    XDG_CONFIG_HOME = "${homeDirectory}/.config";
    XDG_CACHE_HOME = "${homeDirectory}/.cache";
    XDG_DATA_HOME = "${homeDirectory}/.local/share";
    XDG_STATE_HOME = "${homeDirectory}/.local/state";
    XDG_RUNTIME_DIR = "${homeDirectory}/.xdg";
  };
in
{
  system.primaryUser = username;

  # Determinate Nix already manages the Nix daemon and /etc/nix/nix.conf.
  nix.enable = false;

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };

  networking = {
    computerName = "dumpedcore";
    hostName = "dumpedcore";
    localHostName = "dumpedcore";
  };

  environment.variables = xdgEnvironment // {
    FORGIT_NO_ALIASES = "1";
    HOMEBREW_NO_ANALYTICS = "1";
  };

  # Seed the user launchd environment so GUI-launched apps/terminals
  # inherit the same XDG base dirs before any shell startup files run.
  launchd.user.envVariables = xdgEnvironment;

  programs._1password = {
    enable = true;
    package = unstable._1password-cli;
  };

  environment.systemPackages = [
    # Unfree
    unstable._1password-cli
    unstable.claude-code

    # Language/runtime and toolchains.
    glide
    unstable.bun
    unstable.go
    unstable.lua
    unstable.luarocks
    unstable.neovim
    unstable.nodejs
    unstable.openssh
    unstable.python3
    unstable.rustup
    unstable.uv
    unstable.wasmer
    unstable.wasmtime
    unstable.zig


    # Shell/git/search
    unstable.git
    unstable.as-tree
    unstable.chafa
    unstable.colordiff
    unstable.diff-so-fancy
    unstable.difftastic
    unstable.gh
    unstable.ghq
    unstable.glow
    unstable.gnumake
    unstable.gojq
    unstable.gopls
    unstable.gotest
    unstable.gotestsum
    unstable.gotools # includes goimports
    unstable.gum
    unstable.jq
    unstable.mmdbctl
    unstable.yq

    # Docker stuff.
    unstable.docker-client
    unstable.docker-buildx
    unstable.docker-compose

    # Neovim/general language servers and formatters not owned by
    # language runtimes/toolchains.
    unstable.bash-language-server
    unstable.clang-tools
    unstable.fish-lsp
    unstable.fishPlugins.forgit
    unstable.lua-language-server
    unstable.nixd
    unstable.nixfmt
    unstable.protobuf-language-server
    unstable.shellcheck
    unstable.shfmt
    unstable.sourcekit-lsp
    unstable.stylua
    unstable.tailwindcss-language-server
    unstable.tree-sitter
    unstable.taplo
    unstable.terraform-ls
    unstable.typos-lsp
    unstable.typescript-language-server
    unstable.yaml-language-server
    unstable.zls
  ];

  environment.shells = [ pkgs.fish ];
  programs.fish.enable = true;

  users.knownUsers = [ username ];
  users.users.${username} = {
    uid = 501;
    gid = 20;
    home = homeDirectory;
    shell = pkgs.fish;
  };

  homebrew = {
    enable = true;
    enableFishIntegration = true;
    global.autoUpdate = false;
    taps = [
      {
        name = "seruman/local";
        clone_target = "file://${localHomebrewTap}";
      }
    ];
    casks = [
      # Temporary local tap while Homebrew/homebrew-cask#265717 has the
      # stale arm64 checksum for the current 1Password 8.12.21 download.
      "seruman/local/1password"
      "ghostty@tip"
      "orbstack"
      "rectangle"
    ];
    onActivation = {
      cleanup = "none";
      autoUpdate = false;
      upgrade = false;
      extraEnv = {
        HOMEBREW_NO_ANALYTICS = "1";
      };
    };
  };

  system.defaults = {
    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 1;
    };

    finder = {
      QuitMenuItem = true;
      ShowStatusBar = true;
      ShowPathbar = true;
      _FXShowPosixPathInTitle = true;
      NewWindowTarget = "Home";
      FXPreferredViewStyle = "clmv";
    };

    screencapture.location = screenshotsDirectory;
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  system.activationScripts.postActivation.text = ''
    mkdir -p ${lib.escapeShellArg screenshotsDirectory}
    chown ${username}:staff ${lib.escapeShellArg screenshotsDirectory}

    keyboard_layouts_dir=${lib.escapeShellArg "${homeDirectory}/Library/Keyboard Layouts"}
    mkdir -p "$keyboard_layouts_dir"
    install -m 0644 ${turkishKeyboardLayout}/TurkishQLegacyFixed.keylayout "$keyboard_layouts_dir/TurkishQLegacyFixed.keylayout"
    chown ${username}:staff "$keyboard_layouts_dir/TurkishQLegacyFixed.keylayout"
  '';

  system.stateVersion = 6;
}
