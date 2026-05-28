cask "epson-photo-plus" do
  version "4.04.0"
  sha256 "45675f09a85a141f518c79c6f231abf56671caa6728ec90965e9602843e09f07"

  url "https://download.epson-europe.com/pub/download/6762/epson676262eu.dmg"
  name "Epson Photo+"
  desc "Photo layout and printing application for Epson printers"
  homepage "https://www.epson.eu/en_EU/support/sc/epson-l8050/s/s2674"

  pkg "Epson Photo Plus.pkg"

  uninstall pkgutil: "com.epson.pkg.EpsonPhotoPlus",
            delete:  [
              "/Applications/Epson Software/Epson Photo+.app",
              "/Applications/Epson Software/EpsonPhotoPlusTool.app",
            ]
end
