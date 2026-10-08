{
  config,
  inputs,
  lib,
  pkgs,
  pkgsUnstable,
  ...
}:

let
  derivations = import ../packages/derivations.nix {
    inherit
      inputs
      lib
      pkgs
      pkgsUnstable
      ;
  };
  dataDir = "${config.xdg.dataHome}/ollama";
  stateDir = "${config.xdg.stateHome}/ollama";
  logFile = "${stateDir}/server.log";
  endpoint = "http://127.0.0.1:11434";
  request = pkgs.writeText "ollama-clef-preload.json" (
    builtins.toJSON {
      model = "clef-flash:9b-mxfp8";
      state.prompt = "hello";
      questions.tier = {
        type = "choice";
        instructions = "Choose difficulty.";
        criteria = {
          trivial = "Simple";
          standard = "Routine";
          strong = "Difficult";
        };
      };
    }
  );
  preload = pkgs.writeShellScript "ollama-preload" ''
    set -eu
    ready=false
    for ((attempt = 0; attempt < 30; attempt++)); do
      if ${pkgs.curl}/bin/curl --noproxy '*' --fail --silent --show-error \
        --connect-timeout 1 --max-time 2 ${endpoint}/api/version >/dev/null 2>&1; then
        ready=true
        break
      fi
      ${pkgs.coreutils}/bin/sleep 1
    done
    if [ "$ready" != true ]; then
      echo "ollama preload: readiness timed out; server supervision is unaffected" >&2
      exit 1
    fi

    response=$(${pkgs.coreutils}/bin/mktemp)
    trap '${pkgs.coreutils}/bin/rm -f "$response"' EXIT
    # Exactly one bounded request per server start; never a periodic keep-warm.
    if ! ${pkgs.curl}/bin/curl --noproxy '*' --fail --silent --show-error \
      --connect-timeout 2 --max-time 60 ${endpoint}/v1/systemone \
      -H 'Content-Type: application/json' --data-binary @${request} -o "$response"; then
      echo "ollama preload: System One request failed; no automatic retry" >&2
      exit 1
    fi
    if ! ${pkgs.jq}/bin/jq -e '
      .model == "clef-flash:9b-mxfp8" and
      .answers.tier.type == "choice" and
      (.answers.tier.choice | . == "trivial" or . == "standard" or . == "strong")
    ' "$response" >/dev/null; then
      echo "ollama preload: invalid System One answer" >&2
      exit 1
    fi
    echo "ollama preload: Clef ready (30-minute idle residency)"
    ${pkgs.jq}/bin/jq -c . "$response"
  '';
  serve = pkgs.writeShellScript "ollama-serve" ''
    # launchd supervises the exec'd server, not the fallible preload helper.
    # Its default process-group cleanup also stops the helper on server exit.
    ${preload} &
    exec ${lib.getExe derivations.ollama} serve
  '';
  rotation = pkgs.writeText "ollama-logrotate.conf" ''
    "${logFile}" {
      daily
      maxsize 10M
      rotate 7
      compress
      missingok
      notifempty
      # Keep launchd's open log descriptor; do not restart/preload for rotation.
      copytruncate
    }
  '';
in
{
  services.ollama = {
    enable = true;
    package = derivations.ollama;
    host = "127.0.0.1";
    port = 11434;
    environmentVariables = {
      HOME = dataDir;
      OLLAMA_NO_CLOUD = "1";
      OLLAMA_KEEP_ALIVE = "30m";
      OLLAMA_MODELS = "${dataDir}/models";
    };
  };

  # Weights are provisioned once outside Nix; activation never downloads them.
  home.activation.ollamaDirectories =
    lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ]
      ''
        run mkdir -p ${
          lib.escapeShellArgs [
            dataDir
            "${dataDir}/models"
            stateDir
          ]
        }
        run chmod 700 ${
          lib.escapeShellArgs [
            dataDir
            "${dataDir}/models"
            stateDir
          ]
        }
      '';

  launchd.agents = {
    ollama.config = {
      ProgramArguments = lib.mkForce [ "${serve}" ];
      RunAtLoad = true;
      KeepAlive = lib.mkForce true;
      ThrottleInterval = 30;
      Umask = 63; # 0077
      StandardOutPath = logFile;
      StandardErrorPath = logFile;
    };

    # Only log maintenance is periodic. No inference or service restart here.
    ollama-logrotate = {
      enable = true;
      config = {
        ProgramArguments = [
          "${pkgs.logrotate}/bin/logrotate"
          "--state"
          "${stateDir}/logrotate.status"
          "${rotation}"
        ];
        RunAtLoad = true;
        StartInterval = 3600;
        ProcessType = "Background";
        Umask = 63;
        StandardOutPath = logFile;
        StandardErrorPath = logFile;
      };
    };
  };
}
