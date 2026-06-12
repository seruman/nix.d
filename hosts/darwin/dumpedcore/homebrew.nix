{ dumpedcoreHomebrewTap, ... }:

{
  homebrew = {
    taps = [
      {
        name = "seruman/dumpedcore";
        clone_target = "file://${dumpedcoreHomebrewTap}";
        force_auto_update = true;
      }
      {
        name = "lightpanda-io/browser";
        force_auto_update = true;
      }
    ];
    brews = [
      "lightpanda-io/browser/lightpanda"
    ];
    casks = [
      "seruman/dumpedcore/epson-connect-printer-setup"
      "seruman/dumpedcore/epson-l8050-driver"
      "seruman/dumpedcore/epson-photo-plus"
      "seruman/dumpedcore/epson-software-updater"
      "seruman/dumpedcore/unfolder"
      "affinity"
      "chatgpt"
      "ghostty@tip"
      "maccy"
      "mimestream"
      "mullvad-browser"
      "mullvad-vpn"
      "prusaslicer"
      "rectangle"
    ];
    masApps = {
      "Pixelmator Pro" = 1289583905;
      "GarageBand" = 682658836;
      "Ivory for Mastodon by Tapbots" = 6444602274;
      "field-kit" = 1612653346;
    };
  };
}
