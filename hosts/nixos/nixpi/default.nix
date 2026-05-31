{ pkgs, ... }:

let
  user = "seruman";
  ssid = "WIFI_SSID";
  interface = "wlan0";
  secretsDir = "/var/lib/nixos/secrets";
in
{
  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    optimise = {
      automatic = true;
      dates = [ "00:00" ];
    };
  };

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = [
      "xhci_pci"
      "usbhid"
      "usb_storage"
    ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
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

  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "23.11";
}
