{ dumpedcoreHomebrewTap, ... }:

{
  homebrew = {
    taps = [
      {
        name = "seruman/dumpedcore";
        clone_target = "file://${dumpedcoreHomebrewTap}";
        force_auto_update = true;
      }
    ];
    casks = [
      "seruman/dumpedcore/epson-connect-printer-setup"
      "seruman/dumpedcore/epson-l8050-driver"
      "seruman/dumpedcore/epson-photo-plus"
      "seruman/dumpedcore/epson-software-updater"
      "seruman/dumpedcore/unfolder"
      "affinity"
      "mimestream"
      "mullvad-browser"
      "mullvad-vpn"
      "prusaslicer"
    ];
    masApps = {
      "Pixelmator Pro" = 1289583905;
      "GarageBand" = 682658836;
      "Ivory for Mastodon by Tapbots" = 6444602274;
      "field-kit" = 1612653346;
    };
  };
}
