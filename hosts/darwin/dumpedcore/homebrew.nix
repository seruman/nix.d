{ localHomebrewTap, ... }:

{
  homebrew = {
    enable = true;
    enableFishIntegration = true;
    global.autoUpdate = false;
    taps = [
      {
        name = "seruman/local";
        clone_target = "file://${localHomebrewTap}";
        force_auto_update = true;
      }
    ];
    brews = [
      "agent-browser"
    ];
    casks = [
      # Temporary local tap while Homebrew/homebrew-cask#265717 has the
      # stale arm64 checksum for the current 1Password 8.12.21 download.
      "seruman/local/1password"
      "seruman/local/epson-connect-printer-setup"
      "seruman/local/epson-l8050-driver"
      "seruman/local/epson-photo-plus"
      "seruman/local/epson-software-updater"
      {
        name = "seruman/local/teteye";
        greedy = true;
      }
      "seruman/local/unfolder"
      "affinity"
      "chatgpt"
      "ghostty@tip"
      "maccy"
      "mimestream"
      "monodraw"
      "mullvad-browser"
      "mullvad-vpn"
      "orbstack"
      "prusaslicer"
      "rectangle"
      "steermouse"
      "tailscale-app"
    ];
    masApps = {
      "Amphetamine" = 937984704;
      "Pixelmator Pro" = 1289583905;
      "GarageBand" = 682658836;
      "Ivory for Mastodon by Tapbots" = 6444602274;
      "field-kit" = 1612653346;
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
