{
  config,
  lib,
  pkgs,
  inputs,
  pkgsUnstable,
  ...
}:

let
  cfg = config.seruman.darwin;

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
    ./homebrew
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

    filesRoot = lib.mkOption {
      type = lib.types.path;
      default = ./files;
      description = "Root directory for shared dotfiles managed by Home Manager.";
    };

    screenshotsDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.homeDirectory}/etc/screenshots";
      description = "Directory used by macOS screencapture.";
    };

  };

  config = {
    _module.args = {
      inherit pkgsUnstable;
      username = cfg.username;
      homeDirectory = cfg.homeDirectory;
      screenshotsDirectory = cfg.screenshotsDirectory;
      inherit turkishKeyboardLayout;
    };

    system.primaryUser = cfg.username;

    # Determinate Nix already manages the Nix daemon and /etc/nix/nix.conf.
    nix.enable = false;

    nixpkgs = {
      hostPlatform = "aarch64-darwin";
      config.allowUnfree = true;
    };

    system.activationScripts.postActivation.text = ''
      if [ -d "/Applications/Nix Apps/teteye.app" ]; then
        xattr -dr com.apple.quarantine "/Applications/Nix Apps/teteye.app" 2>/dev/null || true
      fi
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
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
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
      extraSpecialArgs = {
        inherit inputs pkgsUnstable turkishKeyboardLayout;
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
