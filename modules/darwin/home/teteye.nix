{ config, lib, ... }:

{
  imports = [ ../../home-manager/teteye.nix ];

  programs.teteye.settings = {
    terminal = {
      font-family = lib.mkDefault "Berkeley Mono";
      font-size = lib.mkDefault 14;
      font-thicken = lib.mkDefault true;
      scrollback-lines = lib.mkDefault 200000000;
      cursor-style = lib.mkDefault "block";
      cursor-blink = lib.mkDefault false;
    };

    colors = {
      background = lib.mkDefault "#F4F0ED";
      foreground = lib.mkDefault "#6B5C4D";
      palette = {
        "0" = lib.mkDefault "#867462";
        "1" = lib.mkDefault "#d7898c";
        "2" = lib.mkDefault "#659e69";
        "3" = lib.mkDefault "#cc7f2b";
        "4" = lib.mkDefault "#485f84";
        "5" = lib.mkDefault "#854882";
        "6" = lib.mkDefault "#436460";
        "7" = lib.mkDefault "#d4cbc3";
        "8" = lib.mkDefault "#a69582";
        "9" = lib.mkDefault "#c65333";
        "10" = lib.mkDefault "#83b887";
        "11" = lib.mkDefault "#c29830";
        "12" = lib.mkDefault "#abb9d6";
        "13" = lib.mkDefault "#be79bb";
        "14" = lib.mkDefault "#729893";
        "15" = lib.mkDefault "#FFFFFF";
      };
    };

    window = {
      padding-x = lib.mkDefault 10;
      opacity = lib.mkDefault 1;
      quit-after-last-window-closed = lib.mkDefault true;
    };

    clipboard = {
      clipboard-read = lib.mkDefault "ask";
      clipboard-write = lib.mkDefault "ask";
      clipboard-trim-trailing-spaces = lib.mkDefault true;
      clipboard-paste-protection = lib.mkDefault true;
      clipboard-paste-bracketed-safe = lib.mkDefault true;
    };

    shell = {
      shell-integration = lib.mkDefault "fish";
      shell-integration-features = lib.mkDefault "no-cursor";
    };

    titlebar.font-family = lib.mkDefault "Berkeley Mono";

    openURL = {
      commandPaths = [
        "${config.home.homeDirectory}/go/bin"
        "${config.home.homeDirectory}/.cargo/bin"
        "${config.home.homeDirectory}/bin"
        "${config.home.homeDirectory}/sbin"
        "${config.home.homeDirectory}/.local/bin"
        "${config.home.homeDirectory}/.nix-profile/bin"
        "/etc/profiles/per-user/${config.home.username}/bin"
        "/run/current-system/sw/bin"
        "/opt/homebrew/bin"
        "/opt/homebrew/sbin"
      ];

      handlers = [
        {
          pattern = "^https://github\\.com/seruman/teteye";
          command = "open-github";
          args = [ "$0" ];
        }
      ];
    };

    keytables = {
      root.binds = [
        {
          key = "cmd+p";
          action = {
            action = "palette";
            target = "commands";
          };
        }
        {
          key = "ctrl+b";
          action = {
            action = "switch-table";
            table = "prefix";
          };
        }
        {
          key = "ctrl+k";
          action.action = "clear-screen";
        }
      ];

      prefix = {
        timeout = {
          ms = lib.mkDefault 1500;
          action = lib.mkDefault "pop";
        };

        binds = [
          {
            key = "minus";
            action = {
              action = "split";
              direction = "down";
            };
          }
          {
            key = "backslash";
            action = {
              action = "split";
              direction = "right";
            };
          }
          {
            key = "o";
            action = {
              action = "palette";
              target = "panes";
              scope = "all-tabs";
            };
          }
          {
            key = "x";
            action.action = "close-pane";
          }
          {
            key = "z";
            action.action = "zoom-pane";
          }
          {
            key = "h";
            action = {
              action = "focus-pane";
              direction = "left";
            };
          }
          {
            key = "j";
            action = {
              action = "focus-pane";
              direction = "down";
            };
          }
          {
            key = "k";
            action = {
              action = "focus-pane";
              direction = "up";
            };
          }
          {
            key = "l";
            action = {
              action = "focus-pane";
              direction = "right";
            };
          }
          {
            key = "c";
            action.action = "new-tab";
          }
          {
            key = "n";
            action.action = "next-tab";
          }
          {
            key = "p";
            action.action = "prev-tab";
          }
          {
            key = "1";
            action = {
              action = "goto-tab";
              index = 0;
            };
          }
          {
            key = "2";
            action = {
              action = "goto-tab";
              index = 1;
            };
          }
          {
            key = "3";
            action = {
              action = "goto-tab";
              index = 2;
            };
          }
          {
            key = "4";
            action = {
              action = "goto-tab";
              index = 3;
            };
          }
          {
            key = "5";
            action = {
              action = "goto-tab";
              index = 4;
            };
          }
          {
            key = "6";
            action = {
              action = "goto-tab";
              index = 5;
            };
          }
          {
            key = "7";
            action = {
              action = "goto-tab";
              index = 6;
            };
          }
          {
            key = "8";
            action = {
              action = "goto-tab";
              index = 7;
            };
          }
          {
            key = "9";
            action = {
              action = "goto-tab";
              index = 8;
            };
          }
          {
            key = "shift+period";
            action = {
              action = "move-tab";
              direction = "right";
            };
          }
          {
            key = "shift+comma";
            action = {
              action = "move-tab";
              direction = "left";
            };
          }
          {
            key = "slash";
            action.action = "search";
          }
          {
            key = "bracketleft";
            action = {
              action = "copy-mode";
              command = "begin";
            };
          }
          {
            key = "r";
            action = {
              action = "switch-table";
              table = "resize";
            };
          }
          {
            key = "escape";
            action.action = "pop";
          }
        ];
      };

      copy = {
        stay = lib.mkDefault true;
        binds = [
          {
            key = "h";
            action = {
              action = "copy-mode";
              command = "move";
              direction = "left";
            };
          }
          {
            key = "j";
            action = {
              action = "copy-mode";
              command = "move";
              direction = "down";
            };
          }
          {
            key = "k";
            action = {
              action = "copy-mode";
              command = "move";
              direction = "up";
            };
          }
          {
            key = "l";
            action = {
              action = "copy-mode";
              command = "move";
              direction = "right";
            };
          }
          {
            key = "ctrl+b";
            action = {
              action = "copy-mode";
              command = "move";
              direction = "page_up";
            };
          }
          {
            key = "ctrl+f";
            action = {
              action = "copy-mode";
              command = "move";
              direction = "page_down";
            };
          }
          {
            key = "0";
            action = {
              action = "copy-mode";
              command = "move";
              direction = "beginning_of_line";
            };
          }
          {
            key = "$";
            action = {
              action = "copy-mode";
              command = "move";
              direction = "end_of_line";
            };
          }
          {
            key = "g";
            action = {
              action = "copy-mode";
              command = "move";
              direction = "home";
            };
          }
          {
            key = "shift+g";
            action = {
              action = "copy-mode";
              command = "move";
              direction = "end";
            };
          }
          {
            key = "v";
            action = {
              action = "copy-mode";
              command = "visual";
              mode = "character";
            };
          }
          {
            key = "shift+v";
            action = {
              action = "copy-mode";
              command = "visual";
              mode = "line";
            };
          }
          {
            key = "ctrl+v";
            action = {
              action = "copy-mode";
              command = "visual";
              mode = "rectangle";
            };
          }
          {
            key = "y";
            action = {
              action = "copy-mode";
              command = "yank";
            };
          }
          {
            key = "enter";
            action = {
              action = "copy-mode";
              command = "yank";
            };
          }
          {
            key = "escape";
            action = {
              action = "copy-mode";
              command = "cancel";
            };
          }
          {
            key = "q";
            action = {
              action = "copy-mode";
              command = "cancel";
            };
          }
        ];
      };

      resize = {
        timeout = {
          ms = lib.mkDefault 3000;
          action = lib.mkDefault "pop";
        };
        stay = lib.mkDefault true;
        binds = [
          {
            key = "h";
            action = {
              action = "resize-pane";
              direction = "left";
              amount = 2;
            };
          }
          {
            key = "j";
            action = {
              action = "resize-pane";
              direction = "down";
              amount = 2;
            };
          }
          {
            key = "k";
            action = {
              action = "resize-pane";
              direction = "up";
              amount = 2;
            };
          }
          {
            key = "l";
            action = {
              action = "resize-pane";
              direction = "right";
              amount = 2;
            };
          }
          {
            key = "=";
            action.action = "equalize-panes";
          }
          {
            key = "enter";
            action.action = "pop-all";
          }
          {
            key = "escape";
            action.action = "pop-all";
          }
        ];
      };
    };
  };
}
