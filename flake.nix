{
  description = "Selman's macOS nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nixpkgs-nixos.url = "github:NixOS/nixpkgs/nixos-25.05";
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

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nixpkgs-nixos,
      ...
    }:
    let
      darwinSystem = "aarch64-darwin";
      linuxSystem = "aarch64-linux";

      darwinPkgs = import nixpkgs {
        system = darwinSystem;
        config.allowUnfree = true;
      };
      darwinPkgsUnstable = import inputs.nixpkgs-unstable {
        system = darwinSystem;
        config.allowUnfree = true;
      };
    in
    {
      darwinModules.common = ./modules/darwin/common.nix;
      homeManagerModules.teteye = ./modules/home-manager/teteye.nix;
      homeManagerModules.teteye-config = ./modules/home-manager/teteye-config.nix;

      darwinConfigurations.dumpedcore = nix-darwin.lib.darwinSystem {
        system = darwinSystem;
        specialArgs = {
          inherit inputs;
          pkgsUnstable = darwinPkgsUnstable;
        };
        modules = [
          ./modules/darwin/common.nix
          ./hosts/darwin/dumpedcore
        ];
      };

      nixosConfigurations.nixpi = nixpkgs-nixos.lib.nixosSystem {
        system = linuxSystem;
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/nixos/nixpi ];
      };

      packages.${darwinSystem} = import ./packages {
        pkgs = darwinPkgs;
        pkgsUnstable = darwinPkgsUnstable;
        inherit inputs;
      };

      devShells.${darwinSystem}.default = darwinPkgs.mkShellNoCC {
        packages = [
          darwinPkgs.fish
          darwinPkgs.nixfmt
          darwinPkgsUnstable.deadnix
          darwinPkgsUnstable.git-filter-repo
          darwinPkgsUnstable.just
          darwinPkgsUnstable.statix
        ];
      };

      formatter.${darwinSystem} = nixpkgs.legacyPackages.${darwinSystem}.nixfmt;
      formatter.${linuxSystem} = nixpkgs-nixos.legacyPackages.${linuxSystem}.nixfmt;

      checks.${darwinSystem} = self.packages.${darwinSystem} // {
        darwin-build = self.darwinConfigurations.dumpedcore.system;
        teteye-config-generation = darwinPkgs.callPackage ./checks/teteye-config-generation.nix {
          inherit (inputs) home-manager;
        };
      };
      checks.${linuxSystem}.nixos-build = self.nixosConfigurations.nixpi.config.system.build.toplevel;
    };
}
