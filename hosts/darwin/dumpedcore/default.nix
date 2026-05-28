{
  inputs,
  pkgs,
  ...
}:

let
  username = "selman";
  homeDirectory = "/Users/${username}";
  screenshotsDirectory = "${homeDirectory}/etc/screenshots";

  opnix = inputs.opnix.packages.${pkgs.stdenv.hostPlatform.system}.default;

  localHomebrewTap =
    pkgs.runCommand "homebrew-seruman-local-tap" { nativeBuildInputs = [ pkgs.git ]; }
      ''
        mkdir -p "$out/Casks"
        cp ${./homebrew-casks/1password.rb} "$out/Casks/1password.rb"
        cp ${./homebrew-casks/epson-connect-printer-setup.rb} "$out/Casks/epson-connect-printer-setup.rb"
        cp ${./homebrew-casks/epson-l8050-driver.rb} "$out/Casks/epson-l8050-driver.rb"
        cp ${./homebrew-casks/epson-photo-plus.rb} "$out/Casks/epson-photo-plus.rb"
        cp ${./homebrew-casks/epson-software-updater.rb} "$out/Casks/epson-software-updater.rb"
        substitute ${./homebrew-casks/teteye.rb} "$out/Casks/teteye.rb" \
          --replace-fail "@opnix@" "${opnix}/bin/opnix"
        cp ${./homebrew-casks/unfolder.rb} "$out/Casks/unfolder.rb"

        git -C "$out" init -q
        git -C "$out" config user.email nix@example.invalid
        git -C "$out" config user.name nix
        git -C "$out" add Casks
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
  imports = [
    ./activation.nix
    ./homebrew.nix
    ./packages.nix
  ];

  _module.args = {
    inherit
      homeDirectory
      localHomebrewTap
      screenshotsDirectory
      username
      ;
  };

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

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  users.knownUsers = [ username ];
  users.users.${username} = {
    uid = 501;
    gid = 20;
    home = homeDirectory;
    shell = pkgs.fish;
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

  system.stateVersion = 6;
}
