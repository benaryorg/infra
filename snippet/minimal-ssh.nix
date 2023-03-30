{ config, pkgs, lib, ... }:

let
  sshkey =
  {
    gnutoo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAsXZcbbZzIjxvguXzAOM/eds9CZl5cqWJBL+ScgHliC benaryorg@gnutoo.home.bsocat.net";
    jumphost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrKgj+479k+nZjVKAeVnh0clxh6MUuEmY0BTtaNMDi5 benaryorg@shell.cloud.bsocat.net";
  };
  useUser = false;
  isContainer = false;
in
  {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    systemd.services.nix-daemon.environment.TMPDIR = "/nix/tmp";
    system.activationScripts.nix-tmpdir =
    ''
      btrfs subvolume create /nix/tmp || mkdir -p /nix/tmp
    '';

    boot.isContainer = isContainer;

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
      unbound.enable = !isContainer;
      rdnssd.enable = isContainer;
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
        psutils pstree
        # shell tooling
        bvi jq moreutils pv tree
        # file tooling
        binwalk detox dos2unix file
        # tui tooling
        tmux
        # debugging
        curl dig htop iftop iotop lsof netcat-openbsd nmap nmon socat tcpdump traceroute whois
        # hardware tooling
        ethtool lsscsi usbutils
        # filesystem tooling
        btrfs-progs cryptsetup dosfstools fio ncdu
      ]
      ++
      lib.optionals (!isContainer)
      [
        # system tooling
        efibootmgr uucp
        (busybox.override { enableStatic = true; enableAppletSymlinks = false; extraConfig = "CONFIG_FEATURE_PREFER_APPLETS=y"; })
        # hardware tooling
        hdparm pciutils smartmontools
        # filesystem tooling
        bcache-tools mdadm
      ]
    ;

    networking =
    {
      firewall.enable = false;
      wireguard.enable = false;
      tempAddresses = "disabled";
      useDHCP = !isContainer;
    };

    system.copySystemConfiguration = !isContainer;

    system.stateVersion = "22.11"; # Did you read the comment?
  }
