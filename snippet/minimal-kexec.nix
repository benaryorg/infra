{ config, pkgs, lib, ... }:

let
  sshkey =
  {
    gnutoo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAsXZcbbZzIjxvguXzAOM/eds9CZl5cqWJBL+ScgHliC benaryorg@gnutoo.home.bsocat.net";
    jumphost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrKgj+479k+nZjVKAeVnh0clxh6MUuEmY0BTtaNMDi5 benaryorg@shell.cloud.bsocat.net";
  };
in
  {
    kexec.autoReboot = false;

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    time.timeZone = "Etc/UTC";
    i18n.defaultLocale = "C.UTF-8";

    users.users.root.openssh.authorizedKeys.keys = lib.attrValues sshkey;

    boot.tmp.useTmpfs = true;

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
        settings =
        {
          PermitRootLogin = "yes";
          PasswordAuthentication = false;
        };
      };
    };

    environment.systemPackages = with pkgs;
      [
        # system tooling
        psutils pstree file
        # shell tooling
        bvi jq moreutils pv tree
        # tui tooling
        tmux
        # debugging
        curl dig htop iftop netcat-openbsd tcpdump
        # filesystem tooling
        btrfs-progs cryptsetup dosfstools
      ]
      ++
      [
        # system tooling
        efibootmgr
        # filesystem tooling
        mdadm
      ]
    ;

    networking =
    {
      firewall.enable = false;
      wireguard.enable = false;
      tempAddresses = "disabled";
      useDHCP = true;
    };

    system.stateVersion = "23.05"; # Did you read the comment?
  }
