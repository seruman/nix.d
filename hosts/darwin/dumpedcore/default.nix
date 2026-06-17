{
  pkgs,
  unstable,
  ...
}:

let
  username = "selman";
  homeDirectory = "/Users/${username}";
  screenshotsDirectory = "${homeDirectory}/etc/screenshots";

  dumpedcoreHomebrewTap =
    pkgs.runCommand "homebrew-seruman-dumpedcore-tap" { nativeBuildInputs = [ pkgs.git ]; }
      ''
        mkdir -p "$out/Casks"
        cp ${./homebrew-casks/epson-connect-printer-setup.rb} "$out/Casks/epson-connect-printer-setup.rb"
        cp ${./homebrew-casks/epson-l8050-driver.rb} "$out/Casks/epson-l8050-driver.rb"
        cp ${./homebrew-casks/epson-photo-plus.rb} "$out/Casks/epson-photo-plus.rb"
        cp ${./homebrew-casks/epson-software-updater.rb} "$out/Casks/epson-software-updater.rb"
        cp ${./homebrew-casks/unfolder.rb} "$out/Casks/unfolder.rb"

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
    ./homebrew.nix
    ./packages.nix
  ];

  _module.args = {
    inherit dumpedcoreHomebrewTap;
  };

  seruman.darwin = {
    inherit
      homeDirectory
      screenshotsDirectory
      username
      ;
    mutableFiles.enable = false;
  };

  networking = {
    computerName = "dumpedcore";
    hostName = "dumpedcore";
    localHostName = "dumpedcore";
  };

  services.tailscale = {
    enable = true;
    package = unstable.tailscale;
  };
}
