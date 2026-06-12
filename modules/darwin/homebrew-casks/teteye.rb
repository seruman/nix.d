require "json"
require "net/http"
require "open3"
require "uri"

class TeteyePrivateGitHubReleaseDownloadStrategy < CurlDownloadStrategy
  OPNIX = "@opnix@"
  OPNIX_TOKEN_FILE = File.expand_path("~/.config/opnix/token")
  OWNER = "seruman"
  REPO = "teteye"
  TAG = "nightly"
  ASSET = "teteye.zip"

  def fetch(timeout: nil)
    token = github_token
    @url = release_asset_url(token)

    original_headers = meta.fetch(:headers, []).dup
    meta[:headers] = original_headers + [
      "Accept: application/octet-stream",
      "Authorization: Bearer #{token}",
    ]

    super
  ensure
    meta[:headers] = original_headers if defined?(original_headers)
  end

  private

  def github_token
    config = JSON.generate({
      vars: [
        {
          name: "TETEYE_RELEASE_TOKEN",
          reference: "op://nix/teteye-release-token/credential",
        },
      ],
    })

    stdout, stderr, status = Open3.capture3(
      OPNIX,
      "env",
      "-token-file",
      OPNIX_TOKEN_FILE,
      "-config-json",
      config,
      "-format",
      "json",
    )

    raise "failed to resolve teteye release token: #{stderr.strip}" unless status.success?

    JSON.parse(stdout).fetch("TETEYE_RELEASE_TOKEN").strip
  end

  def release_asset_url(token)
    uri = URI("https://api.github.com/repos/#{OWNER}/#{REPO}/releases/tags/#{TAG}")
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/vnd.github+json"
    request["Authorization"] = "Bearer #{token}"
    request["X-GitHub-Api-Version"] = "2022-11-28"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    raise "failed to fetch teteye release metadata: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    release = JSON.parse(response.body)
    asset = release.fetch("assets").find { |candidate| candidate.fetch("name") == ASSET }
    raise "teteye release asset not found: #{ASSET}" unless asset

    asset.fetch("url")
  end
end

cask "teteye" do
  version :latest
  sha256 :no_check

  url "https://api.github.com/repos/seruman/teteye/releases/tags/nightly",
      verified: "api.github.com/repos/seruman/teteye/",
      using: TeteyePrivateGitHubReleaseDownloadStrategy

  name "teteye"
  desc "Terminal emulator"
  homepage "https://github.com/seruman/teteye"

  app "teteye.app"

  livecheck do
    skip "Private nightly release"
  end
end
