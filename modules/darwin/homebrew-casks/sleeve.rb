cask "sleeve" do
  version :latest
  sha256 :no_check

  url "https://replay-sleeve-distribution.s3.amazonaws.com/latest/Sleeve.dmg"
  name "Sleeve"
  desc "Music accessory for the Mac"
  homepage "https://replay.software/sleeve"

  auto_updates true

  app "Sleeve.app"

  livecheck do
    skip "Distribution URL always points at latest"
  end

  zap trash: [
    "~/Library/Application Support/Sleeve",
    "~/Library/Caches/com.replay.sleeve",
    "~/Library/Preferences/com.replay.sleeve.plist",
  ]
end
