cask "unfolder" do
  version "2.1.0"
  sha256 "ba390f5acb872e231aa4496748ff89a25d4a9856e3c55ee5f3d34d0b1f8c9ac3"

  url "https://unfolder.app/Unfolder%20#{version}.dmg"
  name "Unfolder"
  desc "3D model unfolding tool for creating papercraft"
  homepage "https://unfolder.app/"

  depends_on macos: ">= :monterey"

  app "Unfolder.app"

  zap trash: [
    "~/Library/Application Support/Unfolder",
    "~/Library/Caches/app.unfolder.UnfolderL",
    "~/Library/HTTPStorages/app.unfolder.UnfolderL",
    "~/Library/Preferences/app.unfolder.UnfolderL.plist",
    "~/Library/Saved Application State/app.unfolder.UnfolderL.savedState",
  ]
end
