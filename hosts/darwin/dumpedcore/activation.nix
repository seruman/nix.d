{
  lib,
  dumpedcoreHomebrewTap,
  pkgs,
  username,
  ...
}:

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
          HOMEBREW_NO_ANALYTICS_MESSAGE_OUTPUT=1 \
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

          brew trust --tap "$tap_name"
        ''}
    fi
  '';

}
