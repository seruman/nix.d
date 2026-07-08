{ ... }:

{
  homebrew = {
    enable = true;
    enableFishIntegration = true;
    global.autoUpdate = false;
    taps = [
      "lightpanda-io/browser"
    ];
    brews = [
      "lightpanda-io/browser/lightpanda"
    ];
    casks = [
      "1password"
      "chatgpt"
      "ghostty@tip"
      "maccy"
      "mimestream"
      "monodraw"
      "orbstack"
      "rectangle"
      "steermouse"
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
        HOMEBREW_NO_AUTO_UPDATE = "1";
        HOMEBREW_NO_ENV_HINTS = "1";
      };
    };
  };
}
