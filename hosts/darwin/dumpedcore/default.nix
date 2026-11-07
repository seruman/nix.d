{
  config,
  lib,
  localPackages,
  pkgs,
  pkgsUnstable,
  username,
  ...
}:

let
  dumpedcoreHomebrewTap =
    pkgs.runCommand "homebrew-seruman-dumpedcore-tap" { nativeBuildInputs = [ pkgs.git ]; }
      ''
        mkdir -p "$out/Casks"
        cp ${./homebrew/casks/epson-connect-printer-setup.rb} "$out/Casks/epson-connect-printer-setup.rb"
        cp ${./homebrew/casks/epson-l8050-driver.rb} "$out/Casks/epson-l8050-driver.rb"
        cp ${./homebrew/casks/epson-photo-plus.rb} "$out/Casks/epson-photo-plus.rb"
        cp ${./homebrew/casks/epson-software-updater.rb} "$out/Casks/epson-software-updater.rb"

        git -C "$out" init -q
        git -C "$out" config user.email nix@example.invalid
        git -C "$out" config user.name nix
        git -C "$out" add Casks
        git -C "$out" commit -q -m init
      '';
in
{
  imports = [
    ./activation.nix
    ./homebrew
    ./packages.nix
  ];

  _module.args = {
    inherit dumpedcoreHomebrewTap;
  };

  networking = {
    computerName = "dumpedcore";
    hostName = "dumpedcore";
    localHostName = "dumpedcore";
  };

  system.defaults.CustomUserPreferences."${
    config.users.users.${username}.home
  }/Library/Containers/doc.md-preview/Data/Library/Preferences/doc.md-preview" =
    lib.mkIf (lib.elem localPackages.markdown-preview config.environment.systemPackages) {
      "MarkdownPreview.sendAnonymousCrashReports" = false;
      "MarkdownPreview.shareAnonymousUsageAnalytics" = false;
      SUEnableAutomaticChecks = false;
      SUAutomaticallyUpdate = false;
      SUSendProfileInfo = false;

      "MarkdownPreview.whatsNewLastBuild" = localPackages.markdown-preview.buildNumber;
      "MarkdownPreview.lastVersion" = localPackages.markdown-preview.version;
    };

  home-manager.users.${username}.programs.teteye.enable = true;

  environment.etc."resolver/ts.net".enable = false;

  services.tailscale = {
    enable = true;
    package = pkgsUnstable.tailscale;
  };
}
