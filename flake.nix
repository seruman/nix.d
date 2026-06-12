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
    inputs@{ nix-darwin, ... }:
    let
      darwinSystem = "aarch64-darwin";
      linuxSystem = "aarch64-linux";
      commonDarwinModule = import ./modules/darwin/common.nix { inherit inputs; };
    in
    {
      darwinModules.common = commonDarwinModule;

      darwinConfigurations.dumpedcore = nix-darwin.lib.darwinSystem {
        system = darwinSystem;
        specialArgs = { inherit inputs; };
        modules = [
          commonDarwinModule
          ./hosts/darwin/dumpedcore
        ];
      };

      nixosConfigurations.nixpi = inputs.nixpkgs-nixos.lib.nixosSystem {
        system = linuxSystem;
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/nixos/nixpi ];
      };
    };
}
