{ pkgs, ... }:

let
  user = "seruman";
  ssid = "WIFI_SSID";
  interface = "wlan0";
  secretsDir = "/var/lib/nixos/secrets";
in
{
  imports = [ ./hardware-configuration.nix ];

  nix = {
    package = pkgs.nixVersions.latest;
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
  ];

  services = {
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
