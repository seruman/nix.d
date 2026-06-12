{ commonHomebrewTap, ... }:

{
  homebrew = {
    enable = true;
    enableFishIntegration = true;
    global.autoUpdate = false;
    taps = [
      {
        name = "seruman/common";
        clone_target = "file://${commonHomebrewTap}";
        force_auto_update = true;
      }
    ];
    casks = [
      # Temporary local tap while Homebrew/homebrew-cask#265717 has the
      # stale arm64 checksum for the current 1Password 8.12.21 download.
      "seruman/common/1password"
      {
        name = "seruman/common/teteye";
        greedy = true;
      }
      "monodraw"
      "orbstack"
      "steermouse"
      "tailscale-app"
    ];
    masApps = {
      "Amphetamine" = 937984704;
    };
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = false;
      upgrade = false;
      extraEnv = {
        HOMEBREW_NO_ANALYTICS = "1";
      };
    };
  };
}
