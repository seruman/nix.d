{ config, inputs, lib, pkgs, ... }:

let
  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  imports = [
    inputs.opnix.homeManagerModules.default
    inputs.pi.homeModules.default
  ];

  home.username = "selman";
  home.homeDirectory = "/Users/selman";

  lib.meta =
    let
      configPath = "${config.home.homeDirectory}/etc/nix";
    in
    {
      inherit configPath;
      mkMutableSymlink = path:
        config.lib.file.mkOutOfStoreSymlink
          (configPath + lib.removePrefix (toString inputs.self) (toString path));
    };

  # Keep this fixed after the first Home Manager activation.
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  programs.man.generateCaches = false;

  programs.pi.coding-agent.enable = true;

  xdg = {
    enable = true;
    localBinInPath = true;
  };

  # Home Manager manages the standard XDG variables via `xdg.enable`; it
  # does not define XDG_RUNTIME_DIR, so keep the location here instead of
  # in Fish startup code.
  home.sessionVariables = {
    XDG_RUNTIME_DIR = "${config.home.homeDirectory}/.xdg";
    EDITOR = "nvim";
    PAGER = "less";
    LESS = "-R --mouse";
    BUN_INSTALL = "${config.home.homeDirectory}/.bun";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/go/bin"
    "${config.home.homeDirectory}/.cargo/bin"
    "${config.home.homeDirectory}/.bun/bin"
    "${config.home.homeDirectory}/bin"
    "${config.home.homeDirectory}/sbin"
  ];

  home.activation.xdgRuntimeDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${lib.escapeShellArg "${config.home.homeDirectory}/.xdg"}
    run chmod 700 ${lib.escapeShellArg "${config.home.homeDirectory}/.xdg"}
  '';

  home.activation.glideWorkConfigSymlink = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    glide_work_link=${lib.escapeShellArg "${config.lib.meta.configPath}/hosts/darwin/dumpedcore/files/glide/glide.work.ts"}
    glide_work_target=${lib.escapeShellArg "${config.xdg.configHome}/work/glide/glide.ts"}

    if [ -e "$glide_work_link" ] && [ ! -L "$glide_work_link" ]; then
      echo "not replacing non-symlink $glide_work_link" >&2
    else
      run ln -sfn "$glide_work_target" "$glide_work_link"
    fi
  '';

  programs.onepassword-secrets = {
    enable = true;
    tokenFile = "${config.xdg.configHome}/opnix/token";
    secrets.braveSearchApiKey = {
      reference = "op://nix/brave-api-key/credential";
      path = ".config/opnix/secrets/brave-search-api-key";
      mode = "0600";
    };
  };

  programs.fish = {
    enable = true;
    package = pkgs.fish;
    # Preserve the old config.fish position: Fish sources conf.d snippets
    # first, then this config body. Keep the body as Fish, not as
    # Nix-translated logic.
    shellInitLast = ''
      source ${config.lib.meta.mkMutableSymlink ./files/fish/config.fish}
    '';
  };

  programs.fzf = {
    enable = true;
    package = unstable.fzf;
    enableFishIntegration = true;
    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--inline-info"
      "--border"
    ];
  };

  programs.zoxide = {
    enable = true;
    package = unstable.zoxide;
    enableFishIntegration = true;
    options = [ "--cmd" "j" ];
  };

  programs.direnv = {
    enable = true;
    package = unstable.direnv;
    enableFishIntegration = true;
  };

  programs.bat = {
    enable = true;
    package = unstable.bat;
    config.theme = "seruzen";
    themes.seruzen = {
      src = ./files/bat/themes;
      file = "seruzen.tmTheme";
    };
  };

  programs.fd = {
    enable = true;
    package = unstable.fd;
    ignores = [
      ".direnv/"
      "vendor/"
      "!.github/"
      ".venv/"
      "envrc/"
      "__pycache__/"
      "node_modules/"
    ];
  };

  programs.ripgrep = {
    enable = true;
    package = unstable.ripgrep;
    arguments = [
      "--hidden"
      "--glob=!.git/"
      "--glob=!{.direnv/,vendor/}"
      "--glob=!{**/.direnv/,**/vendor/}"
      "--glob=!.ropeproject/"
      "--glob=!.venv/"
      "--glob=!.envrc/"
      "--glob=!vendor/"
      "--glob=!__pycache__/"
      "--glob=!node_modules/"
    ];
  };

  programs.tmux = {
    enable = true;
    package = unstable.tmux;
    baseIndex = 1;
    escapeTime = 0;
    focusEvents = true;
    historyLimit = 10000;
    keyMode = "vi";
    mouse = true;
    terminal = "tmux-256color";
    extraConfig = builtins.readFile ./files/tmux/tmux.conf;
    plugins = [
      {
        plugin = unstable.tmuxPlugins.prefix-highlight;
        extraConfig = ''
          set -g @prefix_highlight_show_copy_mode 'on'
          set -g @prefix_highlight_show_sync_mode 'on'
          set -g @prefix_highlight_prefix_prompt 'Wait'
          set -g @prefix_highlight_copy_prompt 'Copy'
          set -g @prefix_highlight_sync_prompt 'Sync'
        '';
      }
    ];
  };

  # Keep ~/.gitconfig managed so stale pre-Nix includes do not override the XDG
  # Git config generated by Home Manager at ~/.config/git/config. Git may ignore
  # the XDG global config when ~/.gitconfig exists, so include it explicitly.
  home.file.".gitconfig".text = ''
    [include]
        path = ~/.config/git/config
  '';

  home.file.".ssh/config.d/1password-agent".text = ''
    Include ~/.ssh/1Password/config

    Host *
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  '';

  programs.git = {
    enable = true;
    # Git itself is installed from nixpkgs-unstable at the system level.
    package = null;

    includes = [
      { path = "~/.config/git/user.gitconfig"; }
      { path = "~/.config/work/gitconfig"; }
    ];

    settings = {
      commit.template = "~/.config/git/committemplate.txt";
      pull.rebase = true;
      push.autoSetupRemote = true;
      difftool.prompt = false;
      merge.conflictstyle = "diff3";
      init.defaultBranch = "main";

      ghq = {
        vsc = "git";
        root = "~/src";
      };

      url."git@github.com:".insteadOf = "https://github.com/";

      alias = {
        stu = "status --untracked-files=no";
        root = "rev-parse --show-toplevel";
        lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --";
        ap = "add --patch";
        psuo = "!git push --set-upstream origin $(git symbolic-ref --short HEAD)";
        "default-branch" = "!git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'";
        cod = "!git checkout $(git default-branch)";
        goreview = "!f() { git diff \${1:-$(git default-branch)} -- . ':(exclude)vendor/'; }; f";
        semtagg = "!f() { tags=$(git semtag -r -ii -fc); if [ -z \"$tags\" ]; then return; else echo \"$tags\" | fzf --ansi; fi; }; f";
        "rebase-squashed" = "!f() { case $# in 0) echo 'Usage: git rebase-squashed [target-branch] <original-branch>'; return 1 ;; 1) target=$(git default-branch); original=$1 ;; *) target=$1; original=$2 ;; esac; git rebase --onto \"$target\" $(git merge-base \"$original\" $(git branch --show-current)); }; f";
        pullt = "pull --tags";
        gone = "!f() { default=$(git default-branch); git branch --format='%(refname:short)' | grep -v \"$default\" | xargs -P8 -I{} sh -c 'git diff --quiet \"$1\"...\"$2\" 2>/dev/null && echo \"$2\"' _ \"$default\" {}; }; f";
        "prune-gone" = "!f() { git fetch -p && branches=$(git gone | fzf --multi --header='Select branches to delete (TAB to multi-select)'); [ -z \"$branches\" ] && return 0; echo \"$branches\" | xargs git branch -D; }; f";
        randomname = "!echo $(LC_ALL=C tr -dc a-z </dev/urandom | head -c4)";
        save = "!f() { git stash push -m \"\${1:-$(git randomname)}\"; }; f";
        new = "!f() { git fetch origin && git checkout -b \"\${1:-$(git randomname)}\" origin/$(git default-branch); }; f";

        dsf = "diff --color";
        dsfw = "dsf --word-diff";
        dsfs = "dsf --staged";
        dsfsw = "dsf --staged --word-diff";

        dshow = "-c diff.external=difft show --ext-diff";
        dtt = "-c diff.external=difft diff";
        dtts = "-c diff.external=difft diff --staged";
        dtreview = "!f() { git -c diff.external=difft diff \${1:-$(git default-branch)} -- . ':(exclude)vendor/'; }; f";

        prcof = "!GH_FORCE_TTY=yes gh pr list | fzf --ansi --header-lines 3 --preview 'GH_FORCE_TTY=yes gh pr view  {1}' | awk '{ print $1}' | xargs -I {} gh pr checkout {}";
      };

      pager.dsf = "diff-so-fancy | less --tabs=4 -RF";

      diff = {
        mmdb = {
          textconv = "~/bin/mmdbexport-git";
          binary = true;
        };
        hex = {
          textconv = "hexdump -v -C";
          binary = true;
        };
        lockb = {
          textconv = "bun";
          binary = true;
        };
      };
    };
  };

  home.file = {
    ".pi/agent/settings.json" = {
      source = config.lib.meta.mkMutableSymlink ./files/pi/agent/settings.json;
      force = true;
    };

    ".pi/agent/APPEND_SYSTEM.md" = {
      source = config.lib.meta.mkMutableSymlink ./files/pi/agent/APPEND_SYSTEM.md;
      force = true;
    };

    "bin/git-histcopy".source = config.lib.meta.mkMutableSymlink ./files/bin/git-histcopy;
    "bin/mmdbexport-git".source = config.lib.meta.mkMutableSymlink ./files/bin/mmdbexport-git;
    "bin/pils".source = config.lib.meta.mkMutableSymlink ./files/bin/pils;
    "bin/tmux-cssh".source = config.lib.meta.mkMutableSymlink ./files/bin/tmux-cssh;
  };

  xdg.configFile = {
    "fish/conf.d".source = config.lib.meta.mkMutableSymlink ./files/fish/conf.d;
    "fish/functions".source = config.lib.meta.mkMutableSymlink ./files/fish/functions;
    "fish/completions".source = config.lib.meta.mkMutableSymlink ./files/fish/completions;
    "fish/pkg".source = config.lib.meta.mkMutableSymlink ./files/fish/pkg;

    "nvim".source = config.lib.meta.mkMutableSymlink ./files/nvim;

    "git/committemplate.txt".text = "";

    "glide".source = config.lib.meta.mkMutableSymlink ./files/glide;
  };

  programs.ghostty = {
    enable = true;
    # Install Ghostty itself with Homebrew `ghostty@tip`.
    package = null;

    settings = {
      "window-padding-x" = 10;
      "window-padding-color" = "background";
      "window-title-font-family" = "Departure Mono";
      "window-new-tab-position" = "end";
      "mouse-hide-while-typing" = false;
      "macos-option-as-alt" = "left";
      "macos-titlebar-style" = "transparent";
      "macos-window-shadow" = true;
      scrollbar = "never";
      "unfocused-split-opacity" = 0.90;
      "copy-on-select" = true;
      "scrollback-limit" = 200000000;
      "quick-terminal-position" = "left";
      "quick-terminal-animation-duration" = 0;
      "quick-terminal-size" = "50%,95%";

      "cursor-style" = "block";
      "cursor-style-blink" = false;
      "cursor-invert-fg-bg" = true;
      "shell-integration" = "fish";
      "shell-integration-features" = "no-cursor";

      keybind = [
        "ctrl+b>n=new_window"
        "ctrl+b>c=new_tab"

        "ctrl+b>n=next_tab"
        "ctrl+b>p=previous_tab"

        "ctrl+b>1=goto_tab:1"
        "ctrl+b>2=goto_tab:2"
        "ctrl+b>3=goto_tab:3"
        "ctrl+b>4=goto_tab:4"
        "ctrl+b>5=goto_tab:5"
        "ctrl+b>6=goto_tab:6"
        "ctrl+b>7=goto_tab:7"
        "ctrl+b>8=goto_tab:8"
        "ctrl+b>9=goto_tab:9"
        "ctrl+b>0=goto_tab:10"

        "ctrl+b>shift+period=move_tab:1"
        "ctrl+b>shift+comma=move_tab:-1"

        "ctrl+b>\\=new_split:right"
        "ctrl+b>-=new_split:down"

        "ctrl+b>l=goto_split:right"
        "ctrl+b>h=goto_split:left"
        "ctrl+b>k=goto_split:top"
        "ctrl+b>j=goto_split:bottom"

        "ctrl+b>shift+l=resize_split:right,100"
        "ctrl+b>shift+h=resize_split:left,100"
        "ctrl+b>shift+k=resize_split:up,100"
        "ctrl+b>shift+j=resize_split:down,100"

        "ctrl+b>z=toggle_split_zoom"
        "ctrl+b>,=prompt_surface_title"

        "ctrl+b>ctrl+b=text:\\x02"

        "ctrl+b>ctrl+n=jump_to_prompt:1"
        "ctrl+b>ctrl+p=jump_to_prompt:-1"

        "ctrl+k=clear_screen"

        "ctrl+b>u=toggle_quick_terminal"
        "global:cmd+shift+u=toggle_quick_terminal"

        "shift+enter=text:\\n"

        "ctrl+b>[=activate_key_table:scrollmode"

        "scrollmode/"
        "scrollmode/j=scroll_page_lines:1"
        "scrollmode/k=scroll_page_lines:-1"

        "scrollmode/ctrl+d=scroll_page_down"
        "scrollmode/ctrl+u=scroll_page_up"
        "scrollmode/ctrl+f=scroll_page_down"
        "scrollmode/ctrl+b=scroll_page_up"
        "scrollmode/shift+j=scroll_page_down"
        "scrollmode/shift+k=scroll_page_up"

        "scrollmode/g>g=scroll_to_top"
        "scrollmode/shift+g=scroll_to_bottom"

        "scrollmode/slash=start_search"
        "scrollmode/n=navigate_search:next"

        "scrollmode/v=activate_key_table:selectmode"

        "scrollmode/shift+semicolon=toggle_command_palette"

        "scrollmode/escape=deactivate_key_table"
        "scrollmode/q=deactivate_key_table"
        "scrollmode/i=deactivate_key_table"

        "scrollmode/catch_all=ignore"

        "selectmode/h=adjust_selection:left"
        "selectmode/l=adjust_selection:right"
        "selectmode/j=adjust_selection:down"
        "selectmode/k=adjust_selection:up"
        "selectmode/0=adjust_selection:beginning_of_line"
        "selectmode/shift+4=adjust_selection:end_of_line"
        "selectmode/g>g=adjust_selection:home"
        "selectmode/shift+g=adjust_selection:end"

        "selectmode/y=copy_to_clipboard"
        "selectmode/escape=deactivate_key_table"
        "selectmode/catch_all=ignore"
      ];

      "font-family" = "Berkeley Mono";
      "font-size" = 14;
      "font-feature" = "-calt";
      "font-thicken" = true;
      "adjust-underline-thickness" = "-50%";
      theme = "seruzen";
      "auto-update-channel" = "tip";
    };

    themes.seruzen = {
      background = "#F4F0ED";
      foreground = "#6B5C4D";
      palette = [
        "0=#867462"
        "1=#d7898c"
        "2=#659e69"
        "3=#cc7f2b"
        "4=#485f84"
        "5=#854882"
        "6=#436460"
        "7=#d4cbc3"
        "8=#a69582"
        "9=#c65333"
        "10=#83b887"
        "11=#c29830"
        "12=#abb9d6"
        "13=#be79bb"
        "14=#729893"
        "15=#FFFFFF"
      ];
      "split-divider-color" = "#d4cbc3";
    };
  };
}
