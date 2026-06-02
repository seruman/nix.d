{ inputs, pkgs, ... }:

let
  user = "seruman";
  ssid = "WIFI_SSID";
  interface = "wlan0";
  secretsDir = "/var/lib/nixos/secrets";
  keepyUser = "keepy";
  keepyGroup = "keepy";
  keepyDataDir = "/var/lib/keepy";
  keepyBinDir = "${keepyDataDir}/bin";
  keepyRuntimeDir = "/run/keepy";
  keepySecretsDir = "${keepyDataDir}/secrets";
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
  opnix = inputs.opnix.packages.${pkgs.system}.default;
  keepyGitHubTokenSecretRef = "op://Homelab/keepy-github-token/password";
  keepyXCookiesSecretRef = "op://Homelab/keepy-x-cookies/password";
  keepyOpnixConfig = pkgs.writeText "keepy-opnix.json" ''
    {
      "secrets": [
        {
          "path": "${keepySecretsDir}/github-token",
          "reference": "${keepyGitHubTokenSecretRef}",
          "owner": "${keepyUser}",
          "group": "${keepyGroup}",
          "mode": "0400"
        },
        {
          "path": "${keepySecretsDir}/x-web-cookies.json",
          "reference": "${keepyXCookiesSecretRef}",
          "owner": "${keepyUser}",
          "group": "${keepyGroup}",
          "mode": "0400"
        }
      ]
    }
  '';
  keepyExec = pkgs.writeShellScript "keepy-start" ''
    set -eu
    export KEEP_GITHUB_TOKEN="$(cat "$CREDENTIALS_DIRECTORY/github-token")"
    export KEEP_X_WEB_COOKIES_PATH="$CREDENTIALS_DIRECTORY/x-web-cookies.json"
    exec ${keepyBinDir}/keep
  '';
in
{
  imports = [ ./hardware-configuration.nix ];

  nix = {
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.nixVersions.latest;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      min-free = 536870912;
      max-free = 2147483648;
    };
    gc = {
      automatic = true;
      dates = "03:15";
      options = "--delete-older-than 7d";
      randomizedDelaySec = "45min";
    };
    optimise = {
      automatic = true;
      dates = [ "04:15" ];
    };
  };

  networking = {
    hostName = "nixpi";
    useDHCP = true;
    wireless = {
      enable = true;
      secretsFile = "${secretsDir}/wireless.env";
      networks.${ssid}.pskRaw = "ext:wifi_psk";
      interfaces = [ interface ];
    };
  };

  environment.systemPackages = with pkgs; [
    htop
    neovim
    nixfmt-rfc-style
    oscclip
    ripgrep
    tailscale
    tmux
    opnix
    unstable.cloudflared
  ];

  services = {
    journald.extraConfig = ''
      SystemMaxUse=200M
      RuntimeMaxUse=50M
      MaxRetentionSec=14day
    '';

    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        hinfo = true;
        userServices = true;
        workstation = true;
      };
    };

    tailscale.enable = true;
  };

  users = {
    mutableUsers = false;
    users.${user} = {
      isNormalUser = true;
      hashedPasswordFile = "${secretsDir}/seruman-password.hash";
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIvzzGm2fRRXrn2n3i1VMe2qNxj1YHD0m/v06JryRtF3"
      ];
    };
    users.${keepyUser} = {
      isSystemUser = true;
      group = keepyGroup;
      home = keepyDataDir;
      createHome = true;
    };
    groups.${keepyGroup} = { };
  };

  systemd.tmpfiles.rules = [
    "d ${keepyDataDir} 0750 ${keepyUser} ${keepyGroup} -"
    "d ${keepyBinDir} 0755 ${keepyUser} ${keepyGroup} -"
    "d ${keepySecretsDir} 0750 ${keepyUser} ${keepyGroup} -"
  ];

  systemd.services.keepy-secrets = {
    description = "keepy runtime secrets via OpNix";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "15min";
      User = "root";
      Group = "root";
    };

    script = ''
      install -d -m 0750 -o ${keepyUser} -g ${keepyGroup} ${keepySecretsDir}
      if [ ! -s ${secretsDir}/opnix-token ]; then
        echo "missing or empty OpNix token: ${secretsDir}/opnix-token" >&2
        exit 1
      fi
      ${opnix}/bin/opnix secret \
        -token-file ${secretsDir}/opnix-token \
        -config ${keepyOpnixConfig} \
        -output /
    '';
  };

  systemd.services.keepy = {
    description = "keepy bookmark server";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network-online.target"
      "keepy-secrets.service"
    ];
    wants = [
      "network-online.target"
      "keepy-secrets.service"
    ];

    serviceConfig = {
      Type = "simple";
      User = keepyUser;
      Group = keepyGroup;
      WorkingDirectory = keepyDataDir;
      ExecStart = "${keepyExec}";
      Restart = "on-failure";
      RestartSec = "5s";
      LoadCredential = [
        "github-token:${keepySecretsDir}/github-token"
        "x-web-cookies.json:${keepySecretsDir}/x-web-cookies.json"
      ];
      StateDirectory = "keepy";
      RuntimeDirectory = "keepy";
      RuntimeDirectoryMode = "0750";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ keepyDataDir ];
    };

    environment = {
      KEEP_LISTEN_ADDR = "127.0.0.1:8080";
      KEEP_DATABASE_PATH = "${keepyDataDir}/keep.db";
      KEEP_LOG_LEVEL = "info";
    };
  };

  security.sudo.extraRules = [
    {
      users = [ user ];
      commands = [
        {
          command = "ALL";
          options = [
            "NOPASSWD"
            "SETENV"
          ];
        }
      ];
    }
  ];

  system.stateVersion = "23.11";
}
