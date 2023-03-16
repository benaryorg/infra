{ name, ragenix, config, pkgs, lib, options, ... }:
with lib;
{
  options =
  {
    benaryorg.base =
    {
      sudo =
      {
        needsPassword = mkOption
        {
          default = false;
          description = "Whether to enable OpenSSH server.";
          type = types.bool;
        };
      };
      gnupg =
      {
        enable = mkOption
        {
          default = false;
          description = "Whether to enable GnuPG.";
          type = types.bool;
        };
      };
    };
  };

  config =
  {
    networking.hostName = head (splitString "." name);
    networking.domain = concatStringsSep "." (tail (splitString "." name));
    networking.search = [ (concatStringsSep "." (tail (splitString "." name))) ];

    time.timeZone = "Etc/UTC";
    i18n.defaultLocale = "C.UTF-8";

    boot.tmpOnTmpfs = true;

    security.sudo =
    {
      enable = true;
      wheelNeedsPassword = config.benaryorg.base.sudo.needsPassword;
      extraRules = mkOrder 1500
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

    virtualisation.containers.enable = true;
    virtualisation.containers.storage.settings.storage.driver = mkDefault "btrfs";

    # fails to start
    systemd.services.mdmonitor.enable = false;

    programs =
    {
      vim.defaultEditor = true;
      mtr.enable = true;
      zsh =
      {
        enable = true;
        enableCompletion = true;
      };
      git =
      {
        enable = true;
        lfs.enable = true;
      };
      gnupg.agent =
      {
        enable = config.benaryorg.base.gnupg.enable;
        pinentryFlavor = "curses";
      };
    };

    services =
    {
      lldpd.enable = true;
      locate.locate = pkgs.mlocate;
      atd.enable = true;
    };

    environment.systemPackages = with pkgs;
    [
      # automation tooling
      colmena ragenix.packages.x86_64-linux.default puppet-bolt
      # network tooling
      dhcpcd dnsmasq iperf
      # system tooling
      btrbk criu efibootmgr psutils pstree podman qemu uucp
      (busybox.override { enableStatic = true; enableAppletSymlinks = false; extraConfig = "CONFIG_FEATURE_PREFER_APPLETS=y"; })
      # misc utils
      cfssl testssl openssl
      # shell tooling
      bvi jq moreutils pv tree
      # file tooling
      binwalk detox dos2unix file
      # tui tooling
      asciinema pass pinentry-curses tmux tmux-xpanes
      # databases
      sqlite
      # debugging
      curl dig gdb htop iftop iotop lsof netcat-openbsd nmap nmon socat strace tcpdump traceroute whois
      # games
      bsdgames
      # hardware tooling
      ethtool hdparm lsscsi pciutils smartmontools usbutils
      # filesystem tooling
      bcache-tools btrfs-progs cryptsetup dosfstools fio mdadm ncdu
    ];

    users.users.root =
    {
      subUidRanges = mkForce [ { startUid = 2000000; count = 1000000; } ];
      subGidRanges = mkForce [ { startGid = 2000000; count = 1000000; } ];
    };

    system.stateVersion = "22.11";
  };
}
