{
  lib,
  dumpedcoreHomebrewTap,
  pkgs,
  homeDirectory,
  username,
  ...
}:

let
  turkishKeyboardLayout = pkgs.fetchFromGitHub {
    owner = "seruman";
    repo = "macos-turkish-keyboard-layout";
    rev = "1d87f298c8e665c8d48fcc184bf364f96d3a1b68";
    hash = "sha256-O0Fn7TtTaj3Puf4CvN0DYDY+hcwb5vJ2D25HXlzayMY=";
  };
in
{
  system.activationScripts.preActivation.text = ''
    if [ -x /opt/homebrew/bin/brew ]; then
      echo >&2 "Updating dumpedcore Homebrew tap..."
      sudo \
        --preserve-env=PATH \
        --user=${lib.escapeShellArg username} \
        --set-home \
        env \
          HOMEBREW_NO_AUTO_UPDATE=1 \
          HOMEBREW_NO_ENV_HINTS=1 \
          HOMEBREW_NO_ANALYTICS=1 \
          PATH="/opt/homebrew/bin:${lib.makeBinPath [ pkgs.git ]}:$PATH" \
        /bin/bash -c ${lib.escapeShellArg ''
          set -euo pipefail
          tap_name=seruman/dumpedcore
          tap_url=file://${dumpedcoreHomebrewTap}
          tap_dir="$(brew --repository "$tap_name" 2>/dev/null || true)"

          if [ -n "$tap_dir" ] && [ -d "$tap_dir/.git" ]; then
            git -C "$tap_dir" remote set-url origin "$tap_url"
            git -C "$tap_dir" fetch --force origin master
            git -C "$tap_dir" reset --hard origin/master
          else
            brew tap "$tap_name" "$tap_url"
          fi
        ''}
    fi
  '';

  system.activationScripts.postActivation.text = ''
    keyboard_layouts_dir=${lib.escapeShellArg "${homeDirectory}/Library/Keyboard Layouts"}
    mkdir -p "$keyboard_layouts_dir"
    install -m 0644 ${turkishKeyboardLayout}/TurkishQLegacyFixed.keylayout "$keyboard_layouts_dir/TurkishQLegacyFixed.keylayout"
    chown ${username}:staff "$keyboard_layouts_dir/TurkishQLegacyFixed.keylayout"
  '';
}
