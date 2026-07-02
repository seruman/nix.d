# Temporary local override for Homebrew/homebrew-cask#265717.
# Upstream cask has a stale/broken arm64 checksum for this same version.
cask "1password" do
  arch arm: "aarch64", intel: "x86_64"

  version "8.12.21"
  sha256 arm:   "5ab59b1b304aeb9b55365f437373a72544623e97db34b3985097154f4113680b",
         intel: "b405a021eee671a1803429fc2abd21ebece6beab9f0c9323cc023716b006364d"

  url "https://downloads.1password.com/mac/1Password-#{version}-#{arch}.zip"
  name "1Password"
  desc "Password manager that keeps all passwords secure behind one password"
  homepage "https://1password.com/"

  auto_updates true
  conflicts_with cask: [
    "1password@beta",
    "1password@nightly",
  ]
  depends_on macos: :monterey

  app "1Password.app"
end
