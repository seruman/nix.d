cask "epson-software-updater" do
  version "2.7.2"
  sha256 "262c2ab27a2e059c2346db8933a96aa65338dab6dd4558d328f7325a48bad14d"

  url "https://download.epson-europe.com/pub/download/6711/epson671139eu.dmg"
  name "Epson Software Updater"
  desc "Updater for Epson software and device firmware"
  homepage "https://www.epson.eu/en_EU/support/sc/epson-l8050/s/s2674"

  auto_updates true

  pkg "EPSON Software Updater.pkg"

  uninstall pkgutil: "com.epson.pkg.EPSONSoftwareUpdater",
            delete:  "/Applications/Epson Software/EPSON Software Updater.app"
end
