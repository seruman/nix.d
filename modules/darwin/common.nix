{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.seruman.darwin;

  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };

  opnix = inputs.opnix.packages.${pkgs.stdenv.hostPlatform.system}.default;

  commonHomebrewTap =
    pkgs.runCommand "homebrew-seruman-common-tap" { nativeBuildInputs = [ pkgs.git ]; }
      ''
        mkdir -p "$out/Casks"
        cp ${./homebrew-casks/1password.rb} "$out/Casks/1password.rb"
        cp ${./homebrew-casks/sleeve.rb} "$out/Casks/sleeve.rb"
        substitute ${./homebrew-casks/teteye.rb} "$out/Casks/teteye.rb" \
          --replace-fail "@opnix@" "${opnix}/bin/opnix"

        git -C "$out" init -q
        git -C "$out" config user.email nix@example.invalid
        git -C "$out" config user.name nix
        git -C "$out" add Casks
        git -C "$out" commit -q -m init
      '';

  turkishKeyboardLayout = pkgs.fetchFromGitHub {
    owner = "seruman";
    repo = "macos-turkish-keyboard-layout";
    rev = "1d87f298c8e665c8d48fcc184bf364f96d3a1b68";
    hash = "sha256-O0Fn7TtTaj3Puf4CvN0DYDY+hcwb5vJ2D25HXlzayMY=";
  };

  xdgEnvironment = {
    XDG_CONFIG_HOME = "${cfg.homeDirectory}/.config";
    XDG_CACHE_HOME = "${cfg.homeDirectory}/.cache";
    XDG_DATA_HOME = "${cfg.homeDirectory}/.local/share";
    XDG_STATE_HOME = "${cfg.homeDirectory}/.local/state";
    XDG_RUNTIME_DIR = "${cfg.homeDirectory}/.xdg";
  };
in
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew
    ./homebrew.nix
    ./packages
  ];

  options.seruman.darwin = {
    username = lib.mkOption {
      type = lib.types.str;
      default = "selman";
      description = "Primary macOS login user managed by the shared Darwin module.";
    };

    uid = lib.mkOption {
      type = lib.types.int;
      default = 501;
      description = "UID for the primary macOS login user.";
    };

    homeDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/Users/${cfg.username}";
      description = "Home directory for the primary macOS login user.";
    };

    configPath = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.homeDirectory}/etc/nix";
      description = "Mutable checkout path used when mutable file links are enabled.";
    };

    sourceRoot = lib.mkOption {
      type = lib.types.str;
      default = inputs.self.outPath;
      description = "Source root of the reusable Darwin configuration.";
    };

    filesRoot = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.sourceRoot}/modules/darwin/files";
      description = "Root directory for shared dotfiles managed by Home Manager.";
    };

    screenshotsDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.homeDirectory}/etc/screenshots";
      description = "Directory used by macOS screencapture.";
    };

    mutableFiles.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use out-of-store symlinks into configPath for shared dotfiles.";
    };
  };

  config = {
    _module.args = {
      inherit unstable;
      username = cfg.username;
      homeDirectory = cfg.homeDirectory;
      screenshotsDirectory = cfg.screenshotsDirectory;
      inherit commonHomebrewTap;
    };

    system.primaryUser = cfg.username;

    # Determinate Nix already manages the Nix daemon and /etc/nix/nix.conf.
    nix.enable = false;

    nixpkgs = {
      hostPlatform = "aarch64-darwin";
      config.allowUnfree = true;
    };

    system.activationScripts.preActivation.text = ''
      if [ -x /opt/homebrew/bin/brew ]; then
        echo >&2 "Updating common Homebrew tap..."
        sudo \
          --preserve-env=PATH \
          --user=${lib.escapeShellArg cfg.username} \
          --set-home \
          env \
            HOMEBREW_NO_AUTO_UPDATE=1 \
            HOMEBREW_NO_ENV_HINTS=1 \
            HOMEBREW_NO_ANALYTICS=1 \
            PATH="/opt/homebrew/bin:${lib.makeBinPath [ pkgs.git ]}:$PATH" \
          /bin/bash -c ${lib.escapeShellArg ''
            set -euo pipefail
            tap_name=seruman/common
            tap_url=file://${commonHomebrewTap}
            tap_dir="$(brew --repository "$tap_name" 2>/dev/null || true)"

            if [ -n "$tap_dir" ] && [ -d "$tap_dir/.git" ]; then
              git -C "$tap_dir" remote set-url origin "$tap_url"
              git -C "$tap_dir" fetch --force origin master
              git -C "$tap_dir" reset --hard origin/master
            else
              brew tap "$tap_name" "$tap_url"
            fi
          ''}
      fi
    '';

    system.activationScripts.postActivation.text = ''
      if [ -d /Applications/teteye.app ]; then
        xattr -dr com.apple.quarantine /Applications/teteye.app 2>/dev/null || true
      fi

      mkdir -p ${lib.escapeShellArg cfg.screenshotsDirectory}
      chown ${cfg.username}:staff ${lib.escapeShellArg cfg.screenshotsDirectory}

      keyboard_layouts_dir=${lib.escapeShellArg "${cfg.homeDirectory}/Library/Keyboard Layouts"}
      mkdir -p "$keyboard_layouts_dir"
      install -m 0644 ${turkishKeyboardLayout}/TurkishQLegacyFixed.keylayout "$keyboard_layouts_dir/TurkishQLegacyFixed.keylayout"
      chown ${cfg.username}:staff "$keyboard_layouts_dir/TurkishQLegacyFixed.keylayout"
    '';

    environment.variables = xdgEnvironment // {
      FORGIT_NO_ALIASES = "1";
      HOMEBREW_NO_ANALYTICS = "1";
      HOMEBREW_NO_AUTO_UPDATE = "1";
      HOMEBREW_NO_ENV_HINTS = "1";
    };

    # Seed the user launchd environment so GUI-launched apps/terminals
    # inherit the same XDG base dirs before any shell startup files run.
    launchd.user.envVariables = xdgEnvironment;

    security.pam.services.sudo_local = {
      touchIdAuth = true;
      reattach = true;
    };

    users.knownUsers = [ cfg.username ];
    users.users.${cfg.username} = {
      uid = cfg.uid;
      gid = 20;
      home = cfg.homeDirectory;
      shell = pkgs.fish;
    };

    system.defaults = {
      NSGlobalDomain = {
        ApplePressAndHoldEnabled = false;
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 15;
        KeyRepeat = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
      };

      CustomUserPreferences = {
        NSGlobalDomain.SLSMenuBarUseBlurredAppearance = 1;

        # Kill the floating "A" language-indicator bubble that pops up next to
        # text cursors when switching input sources. Documented as
        # TSMLanguageIndicatorEnabled on the global domain. Takes effect after
        # re-login.
        NSGlobalDomain.TSMLanguageIndicatorEnabled = 0;
      };

      finder = {
        QuitMenuItem = true;
        ShowStatusBar = true;
        ShowPathbar = true;
        _FXShowPosixPathInTitle = true;
        NewWindowTarget = "Home";
        FXPreferredViewStyle = "clmv";
      };

      controlcenter.BatteryShowPercentage = true;

      dock = {
        orientation = "right";
        show-recents = false;
        tilesize = 44;
      };

      screencapture.location = cfg.screenshotsDirectory;

      WindowManager.EnableStandardClickToShowDesktop = false;
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-backup";
      overwriteBackup = true;
      extraSpecialArgs = {
        inherit inputs unstable;
        serumanDarwin = cfg;
      };
      users.${cfg.username} = import ./home.nix;
    };

    nix-homebrew = {
      enable = true;
      enableRosetta = false;
      user = cfg.username;
      # Let nix-darwin's `homebrew` module own shell integration so it
      # uses the configured prefix and also wires Fish completions.
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableZshIntegration = false;
    };

    system.stateVersion = 6;
  };
}
