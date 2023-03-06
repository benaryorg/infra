{ config, pkgs, lib, ... }:

let
  sshkey =
  {
    gnutoo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAsXZcbbZzIjxvguXzAOM/eds9CZl5cqWJBL+ScgHliC benaryorg@gnutoo.home.bsocat.net";
    jumphost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrKgj+479k+nZjVKAeVnh0clxh6MUuEmY0BTtaNMDi5 benaryorg@shell.cloud.bsocat.net";
  };
  useUser = false;
in
  {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    time.timeZone = "Etc/UTC";
    i18n.defaultLocale = "C.UTF-8";

    users.users.root.openssh.authorizedKeys.keys = lib.attrValues sshkey;
    users.users.benaryorg = lib.mkIf (useUser)
    {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = lib.attrValues sshkey;
    };

    security.sudo =
    {
      enable = true;
      wheelNeedsPassword = false;
      extraRules =
      [
        {
          groups = [ "wheel" ];
          commands =
          [
            { command = "/run/current-system/sw/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }
          ];
        }
      ];
    };

    boot.tmpOnTmpfs = true;

    programs =
    {
      vim.defaultEditor = true;
      mtr.enable = true;
    };

    services =
    {
      lldpd.enable = true;
      unbound.enable = true;
      openssh =
      {
        enable = true;
        permitRootLogin = if useUser then "no" else "yes";
        passwordAuthentication = false;
      };
    };

    environment.systemPackages = with pkgs;
    [
      # system tooling
      efibootmgr psutils pstree uucp
      (busybox.override { enableStatic = true; enableAppletSymlinks = false; extraConfig = "CONFIG_FEATURE_PREFER_APPLETS=y"; })
      # shell tooling
      bvi jq moreutils pv tree
      # file tooling
      binwalk detox dos2unix
      # tui tooling
      tmux
      # debugging
      curl dig htop iftop iotop lsof netcat-openbsd nmap nmon socat tcpdump traceroute whois
      # hardware tooling
      ethtool hdparm lsscsi pciutils smartmontools usbutils
      # filesystem tooling
      bcache-tools btrfs-progs cryptsetup dosfstools fio mdadm ncdu
    ];

    networking =
    {
      firewall.enable = false;
      wireguard.enable = false;
      tempAddresses = "disabled";
      useDHCP = true;
    };

    system.copySystemConfiguration = true;

    system.stateVersion = "22.11"; # Did you read the comment?
  }
