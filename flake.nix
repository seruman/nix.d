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
      localDarwinPackages = import ./modules/darwin/packages/derivations.nix {
        lib = darwinPkgs.lib;
        pkgs = darwinPkgs;
        pkgsUnstable = darwinPkgsUnstable;
        inherit inputs;
      };

      teteyeConfigGenerationCheck =
        let
          testFirst = ./modules/home-manager/files/teteye/config.js;
          testMiddle = darwinPkgs.writeText "teteye-test-middle.js" "";
          testLast = darwinPkgs.writeText "teteye-test-last.js" "";
          testHome = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = darwinPkgs;
            modules = [
              ./modules/home-manager/teteye.nix
              (
                { lib, ... }:
                {
                  programs.teteye.configFiles = lib.mkBefore [ testFirst ];
                }
              )
              {
                home = {
                  username = "tester";
                  homeDirectory = "/Users/tester";
                  stateVersion = "26.05";
                };
                programs.teteye = {
                  enable = true;
                  configFiles = [ testMiddle ];
                };
              }
              (
                { lib, ... }:
                {
                  programs.teteye.configFiles = lib.mkAfter [ testLast ];
                }
              )
            ];
          };
          generatedConfig = testHome.config.xdg.configFile."teteye/config.js".text;
          sourceContext = builtins.getContext (builtins.toJSON testFirst);
          generatedContext = builtins.getContext generatedConfig;
          sourceReferencesPreserved = builtins.all (path: builtins.hasAttr path generatedContext) (
            builtins.attrNames sourceContext
          );
          actualConfig =
            assert sourceReferencesPreserved;
            darwinPkgs.writeText "teteye-test-config.js" generatedConfig;
          expectedConfig = darwinPkgs.writeText "teteye-test-config-expected.js" (
            "teteye.include(${builtins.toJSON testFirst});\n"
            + "teteye.include(${builtins.toJSON testMiddle});\n"
            + "teteye.include(${builtins.toJSON testLast});\n"
          );
        in
        darwinPkgs.runCommand "teteye-config-generation-check" { } ''
          diff -u ${expectedConfig} ${actualConfig}
          test "$(grep -Ec '^teteye\.include\("/nix/store/[^\"]+"\);$' ${actualConfig})" -eq 3
          test -f ${testFirst}
          test -f ${testMiddle}
          test -f ${testLast}
          touch "$out"
        '';
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

      packages.${darwinSystem} = {
        inherit (localDarwinPackages)
          bttf
          cloudflareCf
          gitHunks
          glimpseui
          pi
          sleeve
          teteye
          unfolder
          wb
          ;
        terminal-browser = localDarwinPackages.terminalBrowser;
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

      checks.${darwinSystem} = {
        darwin-build = self.darwinConfigurations.dumpedcore.system;
        teteye-config-generation = teteyeConfigGenerationCheck;
        inherit (self.packages.${darwinSystem})
          bttf
          cloudflareCf
          gitHunks
          glimpseui
          pi
          sleeve
          teteye
          unfolder
          wb
          ;
        terminal-browser = self.packages.${darwinSystem}.terminal-browser;
      };
      checks.${linuxSystem}.nixos-build = self.nixosConfigurations.nixpi.config.system.build.toplevel;
    };
}
