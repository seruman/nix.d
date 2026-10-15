{ pkgs, home-manager }:

let
  testFirst = ../modules/home-manager/files/teteye/config.js;
  testMiddle = pkgs.writeText "teteye-test-middle.js" "";
  testLast = pkgs.writeText "teteye-test-last.js" "";
  testHome = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ../modules/home-manager/teteye.nix
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
    pkgs.writeText "teteye-test-config.js" generatedConfig;
  expectedConfig = pkgs.writeText "teteye-test-config-expected.js" (
    "teteye.include(${builtins.toJSON testFirst});\n"
    + "teteye.include(${builtins.toJSON testMiddle});\n"
    + "teteye.include(${builtins.toJSON testLast});\n"
  );
in
pkgs.runCommand "teteye-config-generation-check" { } ''
  diff -u ${expectedConfig} ${actualConfig}
  test "$(grep -Ec '^teteye\.include\("/nix/store/[^\"]+"\);$' ${actualConfig})" -eq 3
  test -f ${testFirst}
  test -f ${testMiddle}
  test -f ${testLast}
  touch "$out"
''
