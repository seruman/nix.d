cask "epson-connect-printer-setup" do
  version "2.2.0"
  sha256 "b1b00c71534446e80c8732836b619df39ed4262bc60b7e41cea126daa82274b8"

  url "https://download.epson-europe.com/pub/download/6770/epson677079eu.dmg"
  name "Epson Connect Printer Setup"
  desc "Setup utility for Epson Connect email and cloud printing services"
  homepage "https://www.epson.eu/en_EU/support/sc/epson-l8050/s/s2674"

  pkg "Epson Connect Printer Setup.pkg"

  uninstall pkgutil: [
              "com.epson.fpkg.ECPS1013.220",
              "com.epson.fpkg.ECPS1100.220",
            ],
            delete:  "/Applications/Epson Software/Epson Connect Printer Setup.app"
end
