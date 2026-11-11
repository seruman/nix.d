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
      # Epson installers write printer drivers, USB kexts, pkg receipts, and apps
      # under /Library and /Applications/Epson Software; keep Homebrew as the pkg owner.
      "seruman/dumpedcore/epson-connect-printer-setup"
      "seruman/dumpedcore/epson-l8050-driver"
      "seruman/dumpedcore/epson-photo-plus"
      "seruman/dumpedcore/epson-software-updater"
      "affinity"
      "mullvad-browser"
      "mullvad-vpn"
      "prusaslicer"
    ];
    masApps = {
      "Pixelmator Pro" = 1289583905;
      "GarageBand" = 682658836;
      "Xcode" = 497799835;
      "Ivory for Mastodon by Tapbots" = 6444602274;
      "field-kit" = 1612653346;
    };
  };
}
