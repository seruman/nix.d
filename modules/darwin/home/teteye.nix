{
  config,
  lib,
  serumanDarwin,
  ...
}:

let
  cfg = config.seruman.teteye;
  inherit (lib)
    concatMapStringsSep
    concatStringsSep
    filterAttrs
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  scalarType = types.oneOf [
    types.str
    types.int
    types.float
    types.bool
  ];

  scalarOrListType = types.either scalarType (types.listOf scalarType);
  attrsOfScalarType = types.attrsOf scalarType;
  attrsOfNullableScalarOrListType = types.attrsOf (types.nullOr scalarOrListType);

  renderScalar =
    value:
    if builtins.isString value then
      builtins.toJSON value
    else if builtins.isBool value then
      lib.boolToString value
    else
      toString value;

  renderProperties =
    properties:
    let
      nonNullProperties = filterAttrs (_: value: value != null) properties;
    in
    concatMapStringsSep "" (name: " ${name}=${renderScalar nonNullProperties.${name}}") (
      builtins.attrNames nonNullProperties
    );

  indent = level: concatStringsSep "" (builtins.genList (_: "    ") level);

  renderNode =
    level: name: arguments: properties: children:
    let
      prefix = indent level;
      argumentsText = concatMapStringsSep "" (argument: " ${renderScalar argument}") arguments;
      propertiesText = renderProperties properties;
    in
    if children == [ ] then
      "${prefix}${name}${argumentsText}${propertiesText}"
    else
      "${prefix}${name}${argumentsText}${propertiesText} {\n${concatStringsSep "\n" children}\n${prefix}}";

  renderRepeatedNode =
    level: name: value:
    if builtins.isList value then
      concatMapStringsSep "\n" (item: renderNode level name [ item ] { } [ ]) value
    else
      renderNode level name [ value ] { } [ ];

  renderSectionAttrs =
    name: attrs:
    let
      nonNullAttrs = filterAttrs (_: value: value != null) attrs;
      children = mapAttrsToList (key: value: renderRepeatedNode 1 key value) nonNullAttrs;
    in
    renderNode 0 name [ ] { } children;

  renderColors =
    let
      colorAttrs = builtins.removeAttrs cfg.colors [ "palette" ];
      colorNodes = mapAttrsToList (name: value: renderRepeatedNode 1 name value) (
        filterAttrs (_: value: value != null) colorAttrs
      );
      paletteKeys = builtins.sort (left: right: (builtins.fromJSON left) < (builtins.fromJSON right)) (
        builtins.attrNames cfg.colors.palette
      );
      paletteNodes = map (
        index: renderNode 1 "palette" [ ] { ${index} = cfg.colors.palette.${index}; } [ ]
      ) paletteKeys;
    in
    renderNode 0 "colors" [ ] { } (colorNodes ++ paletteNodes);

  renderShell =
    let
      shellAttrs = builtins.removeAttrs cfg.shell [ "env" ];
      shellNodes = mapAttrsToList (name: value: renderRepeatedNode 1 name value) (
        filterAttrs (_: value: value != null) shellAttrs
      );
      envNodes = mapAttrsToList (
        name: value: renderNode 1 "env" [ ] { ${name} = value; } [ ]
      ) cfg.shell.env;
    in
    renderNode 0 "shell" [ ] { } (shellNodes ++ envNodes);

  renderActionProperties = action: {
    command = action.command;
    url-template = action.urlTemplate;
  };

  renderActionChildren =
    level: action: map (argument: renderNode level "arg" [ argument ] { } [ ]) action.args;

  renderLink =
    link:
    renderNode 1 "link" [ link.pattern ] (renderActionProperties link) (renderActionChildren 2 link);

  renderLinks = renderNode 0 "links" [ ] { } (map renderLink cfg.links);

  renderOpenURLHandler =
    handler:
    renderNode 1 "handler" [ handler.pattern ] (renderActionProperties handler) (
      renderActionChildren 2 handler
    );

  renderOpenURL = renderNode 0 "open-url" [ ] { } (
    (map (path: renderNode 1 "path" [ path ] { } [ ]) cfg.openURL.commandPaths)
    ++ (map renderOpenURLHandler cfg.openURL.handlers)
  );

  renderKeyBind = bind: renderNode 1 "bind" [ bind.key ] bind.action [ ];

  renderKeyTable =
    table:
    let
      timeoutNode =
        if table.timeout == null then [ ] else [ (renderNode 1 "timeout" [ ] table.timeout [ ]) ];
      passthroughNode =
        if table.passthrough == null then
          [ ]
        else
          [ (renderNode 1 "passthrough" [ table.passthrough ] { } [ ]) ];
      stayNode = if table.stay == null then [ ] else [ (renderNode 1 "stay" [ table.stay ] { } [ ]) ];
    in
    renderNode 0 "keytable" [ table.name ] { } (
      timeoutNode ++ passthroughNode ++ stayNode ++ (map renderKeyBind table.binds)
    );

  actionType = types.submodule {
    options = {
      pattern = mkOption { type = types.str; };
      command = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      urlTemplate = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      args = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
    };
  };

  keyBindType = types.submodule {
    options = {
      key = mkOption { type = types.str; };
      action = mkOption { type = attrsOfScalarType; };
    };
  };

  keyTableType = types.submodule {
    options = {
      name = mkOption { type = types.str; };
      timeout = mkOption {
        type = types.nullOr attrsOfScalarType;
        default = null;
      };
      passthrough = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };
      stay = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };
      binds = mkOption {
        type = types.listOf keyBindType;
        default = [ ];
      };
    };
  };

  generatedConfig = concatStringsSep "\n\n" (
    [
      (renderSectionAttrs "terminal" cfg.terminal)
      renderColors
      (renderSectionAttrs "window" cfg.window)
      (renderSectionAttrs "clipboard" cfg.clipboard)
      renderShell
      (renderSectionAttrs "titlebar" cfg.titlebar)
    ]
    ++ lib.optional (cfg.links != [ ]) renderLinks
    ++ [ renderOpenURL ]
    ++ (map renderKeyTable cfg.keytables)
    ++ lib.optional (cfg.extraConfig != "") cfg.extraConfig
  );
in
{
  options.seruman.teteye = {
    enable = mkEnableOption "Teteye config generation" // {
      default = true;
    };

    terminal = mkOption {
      type = attrsOfNullableScalarOrListType;
      default = {
        font-family = "Berkeley Mono";
        font-size = 14;
        font-thicken = true;
        scrollback-lines = 200000000;
        cursor-style = "block";
        cursor-blink = false;
      };
    };

    colors = mkOption {
      type = types.submodule {
        freeformType = attrsOfNullableScalarOrListType;
        options.palette = mkOption {
          type = types.attrsOf types.str;
          default = { };
        };
      };
      default = {
        background = "#F4F0ED";
        foreground = "#6B5C4D";
        palette = {
          "0" = "#867462";
          "1" = "#d7898c";
          "2" = "#659e69";
          "3" = "#cc7f2b";
          "4" = "#485f84";
          "5" = "#854882";
          "6" = "#436460";
          "7" = "#d4cbc3";
          "8" = "#a69582";
          "9" = "#c65333";
          "10" = "#83b887";
          "11" = "#c29830";
          "12" = "#abb9d6";
          "13" = "#be79bb";
          "14" = "#729893";
          "15" = "#FFFFFF";
        };
      };
    };

    window = mkOption {
      type = attrsOfNullableScalarOrListType;
      default = {
        padding-x = 10;
        opacity = 1;
        quit-after-last-window-closed = true;
      };
    };

    clipboard = mkOption {
      type = attrsOfNullableScalarOrListType;
      default = {
        clipboard-read = "ask";
        clipboard-write = "ask";
        clipboard-trim-trailing-spaces = true;
        clipboard-paste-protection = true;
        clipboard-paste-bracketed-safe = true;
      };
    };

    shell = mkOption {
      type = types.submodule {
        freeformType = attrsOfNullableScalarOrListType;
        options.env = mkOption {
          type = types.attrsOf types.str;
          default = { };
        };
      };
      default = {
        shell-integration = "fish";
        shell-integration-features = "no-cursor";
      };
    };

    titlebar = mkOption {
      type = attrsOfNullableScalarOrListType;
      default = {
        font-family = "Berkeley Mono";
      };
    };

    links = mkOption {
      type = types.listOf actionType;
      default = [ ];
    };

    openURL = {
      commandPaths = mkOption {
        type = types.listOf types.str;
        default = [
          "${serumanDarwin.homeDirectory}/go/bin"
          "${serumanDarwin.homeDirectory}/.cargo/bin"
          "${serumanDarwin.homeDirectory}/bin"
          "${serumanDarwin.homeDirectory}/sbin"
          "${serumanDarwin.homeDirectory}/.local/bin"
          "${serumanDarwin.homeDirectory}/.nix-profile/bin"
          "/etc/profiles/per-user/${serumanDarwin.username}/bin"
          "/run/current-system/sw/bin"
          "/opt/homebrew/bin"
          "/opt/homebrew/sbin"
        ];
      };

      handlers = mkOption {
        type = types.listOf actionType;
        default = [
          {
            pattern = "^https://github\\.com/seruman/teteye";
            command = "open-github";
            args = [ "$0" ];
          }
        ];
      };
    };

    keytables = mkOption {
      type = types.listOf keyTableType;
      default = [
        {
          name = "root";
          binds = [
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
        }
        {
          name = "prefix";
          timeout = {
            ms = 1500;
            action = "pop";
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
          ]
          ++ (builtins.genList (index: {
            key = toString (index + 1);
            action = {
              action = "goto-tab";
              index = index;
            };
          }) 9)
          ++ [
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
        }
        {
          name = "copy";
          stay = true;
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
        }
        {
          name = "resize";
          timeout = {
            ms = 3000;
            action = "pop";
          };
          stay = true;
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
        }
      ];
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."teteye/config.kdl".text = generatedConfig;
  };
}
