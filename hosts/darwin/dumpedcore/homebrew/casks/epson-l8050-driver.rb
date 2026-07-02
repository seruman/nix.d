cask "epson-l8050-driver" do
  version "13.26"
  sha256 "2f7b41fa02fc77326b7df7583d66f0d56f54c0ecaaad592aa79cb4d5c22549f1"

  url "https://download.epson-europe.com/pub/download/6672/epson667222eu.dmg"
  name "Epson L8050 Driver"
  desc "Printer driver for Epson L8050 / ET-18100 series"
  homepage "https://www.epson.eu/en_EU/support/sc/epson-l8050/s/s2674"

  pkg "EPSON Printer.pkg"

  uninstall pkgutil: [
    "com.epson.pkg.ijpdrv.et-18100series.w.Machine_106_and_later",
    "com.epson.pkg.ijpdrv.et-18100series.w.Module_106_1015",
    "com.epson.pkg.ijpdrv.et-18100series.w.Module_110_and_later",
    "com.epson.pkg.ijpdrv.et-18100series.w.USBClassDriver",
    "com.epson.pkg.ijpdrv.et-18100series.w.USBClassDriver_107_and_later",
  ]
end
