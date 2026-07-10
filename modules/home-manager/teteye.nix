{ config, lib, ... }:

let
  cfg = config.programs.teteye;
  settings = cfg.settings;
  inherit (lib)
    concatMapStringsSep
    concatStringsSep
    filterAttrs
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    optional
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
  sectionType = types.attrsOf (types.nullOr scalarOrListType);

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
      values = filterAttrs (_: value: value != null) properties;
    in
    concatMapStringsSep "" (name: " ${name}=${renderScalar values.${name}}") (
      builtins.attrNames values
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

  renderSection =
    name: values:
    let
      presentValues = filterAttrs (_: value: value != null) values;
      children = mapAttrsToList (key: value: renderRepeatedNode 1 key value) presentValues;
    in
    if children == [ ] then null else renderNode 0 name [ ] { } children;

  paletteKeys = builtins.attrNames settings.colors.palette;
  paletteKeysAreNumeric = builtins.all (key: builtins.match "[0-9]+" key != null) paletteKeys;

  renderColors =
    let
      colorValues = filterAttrs (_: value: value != null) (
        builtins.removeAttrs settings.colors [ "palette" ]
      );
      colorNodes = mapAttrsToList (name: value: renderRepeatedNode 1 name value) colorValues;
      sortedPaletteKeys =
        if paletteKeysAreNumeric then
          builtins.sort (left: right: (builtins.fromJSON left) < (builtins.fromJSON right)) paletteKeys
        else
          paletteKeys;
      paletteNodes = map (
        index: renderNode 1 "palette" [ ] { ${index} = settings.colors.palette.${index}; } [ ]
      ) sortedPaletteKeys;
      children = colorNodes ++ paletteNodes;
    in
    if children == [ ] then null else renderNode 0 "colors" [ ] { } children;

  renderShell =
    let
      shellValues = filterAttrs (_: value: value != null) (builtins.removeAttrs settings.shell [ "env" ]);
      shellNodes = mapAttrsToList (name: value: renderRepeatedNode 1 name value) shellValues;
      envNodes = mapAttrsToList (
        name: value: renderNode 1 "env" [ ] { ${name} = value; } [ ]
      ) settings.shell.env;
      children = shellNodes ++ envNodes;
    in
    if children == [ ] then null else renderNode 0 "shell" [ ] { } children;

  renderActionProperties = action: {
    command = action.command;
    url-template = action.urlTemplate;
  };

  renderActionChildren =
    level: action: map (argument: renderNode level "arg" [ argument ] { } [ ]) action.args;

  renderLink =
    link:
    renderNode 1 "link" [ link.pattern ] (renderActionProperties link) (renderActionChildren 2 link);

  renderLinks =
    if settings.links == [ ] then
      null
    else
      renderNode 0 "links" [ ] { } (map renderLink settings.links);

  renderOpenURLHandler =
    handler:
    renderNode 1 "handler" [ handler.pattern ] (renderActionProperties handler) (
      renderActionChildren 2 handler
    );

  renderOpenURL =
    let
      children =
        (map (path: renderNode 1 "path" [ path ] { } [ ]) settings.openURL.commandPaths)
        ++ (map renderOpenURLHandler settings.openURL.handlers);
    in
    if children == [ ] then null else renderNode 0 "open-url" [ ] { } children;

  renderKeyBind = bind: renderNode 1 "bind" [ bind.key ] bind.action [ ];

  renderKeyTable =
    name: table:
    let
      timeoutNode = optional (table.timeout != null) (renderNode 1 "timeout" [ ] table.timeout [ ]);
      passthroughNode = optional (table.passthrough != null) (
        renderNode 1 "passthrough" [ table.passthrough ] { } [ ]
      );
      stayNode = optional (table.stay != null) (renderNode 1 "stay" [ table.stay ] { } [ ]);
    in
    renderNode 0 "keytable" [ name ] { } (
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

  configuredActions = settings.links ++ settings.openURL.handlers;
  actionAssertions = map (action: {
    assertion = (action.command != null) != (action.urlTemplate != null);
    message = ''
      programs.teteye action ${builtins.toJSON action.pattern} must set exactly one of
      `command` or `urlTemplate`.
    '';
  }) configuredActions;

  fragments = [
    (renderSection "terminal" settings.terminal)
    renderColors
    (renderSection "window" settings.window)
    (renderSection "clipboard" settings.clipboard)
    renderShell
    (renderSection "titlebar" settings.titlebar)
    renderLinks
    renderOpenURL
    (renderSection "macos" settings.macos)
    (renderSection "ipc" settings.ipc)
  ]
  ++ mapAttrsToList renderKeyTable settings.keytables
  ++ optional (cfg.extraConfig != "") cfg.extraConfig;

  generatedConfig = concatStringsSep "\n\n" (builtins.filter (fragment: fragment != null) fragments);
in
{
  options.programs.teteye = {
    enable = mkEnableOption "Teteye config generation";

    settings = {
      terminal = mkOption {
        type = sectionType;
        default = { };
      };

      colors = mkOption {
        type = types.submodule {
          freeformType = sectionType;
          options.palette = mkOption {
            type = types.attrsOf types.str;
            default = { };
          };
        };
        default = { };
      };

      window = mkOption {
        type = sectionType;
        default = { };
      };

      clipboard = mkOption {
        type = sectionType;
        default = { };
      };

      shell = mkOption {
        type = types.submodule {
          freeformType = sectionType;
          options.env = mkOption {
            type = types.attrsOf types.str;
            default = { };
          };
        };
        default = { };
      };

      titlebar = mkOption {
        type = sectionType;
        default = { };
      };

      links = mkOption {
        type = types.listOf actionType;
        default = [ ];
      };

      openURL = {
        commandPaths = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };

        handlers = mkOption {
          type = types.listOf actionType;
          default = [ ];
        };
      };

      macos = mkOption {
        type = sectionType;
        default = { };
      };

      ipc = mkOption {
        type = sectionType;
        default = { };
      };

      keytables = mkOption {
        type = types.attrsOf keyTableType;
        default = { };
      };
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = paletteKeysAreNumeric;
        message = "programs.teteye.settings.colors.palette keys must be decimal integers.";
      }
    ]
    ++ actionAssertions;

    xdg.configFile."teteye/config.kdl".text = generatedConfig;
  };
}
