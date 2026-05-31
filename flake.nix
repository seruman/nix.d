{
  description = "Selman's macOS nix-darwin configuration";

  inputs = {
    # Stable base for nix-darwin/Home Manager/system plumbing.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    # Stable base for NixOS hosts.
    nixpkgs-nixos.url = "github:NixOS/nixpkgs/nixos-25.05";

    # Selective bleeding-edge packages, used explicitly by host configs.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    glide.url = "github:glide-browser/glide.nix";
    glide.inputs.nixpkgs.follows = "nixpkgs-unstable";
    glide.inputs.home-manager.follows = "home-manager";

    opnix.url = "github:brizzbuzz/opnix";
    opnix.inputs.nixpkgs.follows = "nixpkgs-unstable";

    pi.url = "github:lukasl-dev/pi.nix";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs =
    inputs@{
      nix-darwin,
      home-manager,
      nix-homebrew,
      ...
    }:
    let
      darwinSystem = "aarch64-darwin";
      linuxSystem = "aarch64-linux";
      unstable = import inputs.nixpkgs-unstable {
        system = darwinSystem;
        config.allowUnfree = true;
      };
    in
    {
      darwinConfigurations.dumpedcore = nix-darwin.lib.darwinSystem {
        system = darwinSystem;
        specialArgs = { inherit inputs unstable; };
        modules = [
          ./hosts/darwin/dumpedcore

          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew

          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-backup";
              overwriteBackup = true;
              extraSpecialArgs = { inherit inputs unstable; };
              users.selman = import ./hosts/darwin/dumpedcore/home.nix;
            };

            nix-homebrew = {
              enable = true;
              enableRosetta = false;
              user = "selman";
              # Let nix-darwin's `homebrew` module own shell integration so it
              # uses the configured prefix and also wires Fish completions.
              enableBashIntegration = false;
              enableFishIntegration = false;
              enableZshIntegration = false;
            };
          }
        ];
      };

      nixosConfigurations.nixpi = inputs.nixpkgs-nixos.lib.nixosSystem {
        system = linuxSystem;
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/nixos/nixpi ];
      };
    };
}
