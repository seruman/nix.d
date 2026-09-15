{ inputs, pkgs, ... }:

let
  user = "seruman";
  interface = "wlan0";
  secretsDir = "/var/lib/nixos/secrets";
  nixRepoDeployKeyPath = "/home/${user}/.ssh/nix-d-deploy-key";
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
      interfaces = [ interface ];
    };
  };

  boot.extraModprobeConfig = ''
    options brcmfmac roamoff=1
  '';

  environment.systemPackages = with pkgs; [
    gitMinimal
    htop
    iw
    neovim
    nixfmt-rfc-style
    oscclip
    ripgrep
    tailscale
    tmux
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

  programs.ssh = {
    extraConfig = ''
      Host github.com-seruman-nix-d
        HostName github.com
        User git
        IdentityFile ${nixRepoDeployKeyPath}
        IdentitiesOnly yes
        HostKeyAlias github.com-seruman-nix-d
    '';
    knownHosts."github.com-seruman-nix-d".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
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
  };

  systemd.tmpfiles.rules = [ "d /home/${user}/.ssh 0700 ${user} users -" ];

  systemd.services.wifi-power-save-off = {
    description = "Disable wlan0 Wi-Fi power save";
    wantedBy = [ "multi-user.target" ];
    after = [
      "wpa_supplicant-wlan0.service"
      "dhcpcd.service"
    ];
    wants = [
      "wpa_supplicant-wlan0.service"
      "dhcpcd.service"
    ];

    serviceConfig = {
      Type = "oneshot";
      User = "root";
      Group = "root";
      ExecStart = "${pkgs.iw}/bin/iw dev ${interface} set power_save off";
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
