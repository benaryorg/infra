{ name, config, pkgs, lib, options, nodes, ... }:
{
  options =
  {
    benaryorg.base =
    {
      sudo =
      {
        needsPassword = lib.mkOption
        {
          default = false;
          description = "Whether sudo needs a password for base users.";
          type = lib.types.bool;
        };
      };
      gnupg =
      {
        enable = lib.mkEnableOption (lib.mdDoc "GnuPG");
      };
      lightweight = lib.mkOption
      {
        default = false;
        description = "Enabling this will remove some larger packages.";
        type = lib.types.bool;
      };
    };
  };

  config =
  {
    networking.hostName = builtins.head (lib.splitString "." name);
    networking.domain = lib.concatStringsSep "." (builtins.tail (lib.splitString "." name));
    networking.search = [ (lib.concatStringsSep "." (builtins.tail (lib.splitString "." name))) ];
    networking.hosts = lib.mkForce {};

    time.timeZone = "Etc/UTC";
    i18n.defaultLocale = "C.UTF-8";

    boot.tmp.useTmpfs = true;

    security.sudo =
    {
      enable = true;
      wheelNeedsPassword = config.benaryorg.base.sudo.needsPassword;
    };

    virtualisation.containers =
    {
      enable = true;
      # upstream default, except for driver=btrfs
      storage.settings =
      {
        storage =
        {
          driver = "btrfs";
          graphroot = "/var/lib/containers/storage";
          runroot = "/run/containers/storage";
        };
      };
    };

    # fails to start
    systemd.services.mdmonitor.enable = false;
    systemd.services.nginx.unitConfig.StartLimitIntervalSec = lib.mkDefault 300;

    systemd.extraConfig =
    ''
      DefaultRestartSec=1
      DefaultStartLimitIntervalSec=300
      DefaultStartLimitBurst=60
    '';

    systemd.tmpfiles.rules = [ "v '/mnt' 0755 root root - -" ];

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
      ssh.knownHosts = lib.pipe nodes
      [
        (builtins.mapAttrs (_: { config, ... }: config.benaryorg.ssh.hostkey))
        (lib.filterAttrs (_: builtins.isString))
        (builtins.mapAttrs (_: key: { publicKey = key; }))
      ];
    };

    services =
    {
      lldpd.enable = true;
      atd.enable = true;
      locate =
      {
        enable = true;
        interval = "daily";
        package = pkgs.mlocate;
        localuser = null;
      };
      journald.extraConfig =
      ''
        SystemMaxUse=2G
      '';
    };

    environment.systemPackages = with pkgs; builtins.concatLists
    [
      [
        # automation tooling
        colmena ragenix nix-diff
        # network tooling
        dhcpcd dnsmasq iperf
        # system tooling
        btrbk efibootmgr psutils pstree uucp
        (busybox.override { enableStatic = true; enableAppletSymlinks = false; extraConfig = "CONFIG_FEATURE_SH_STANDALONE y"; })
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
        curl dig htop iftop iotop lsof netcat-openbsd nmap nmon socat strace tcpdump traceroute whois
        # hardware tooling
        ethtool hdparm lsscsi pciutils smartmontools usbutils
        # filesystem tooling
        bcache-tools btrfs-progs cryptsetup dosfstools fio mdadm ncdu
      ]
      (lib.optionals (!config.benaryorg.base.lightweight)
      [
        # automation tooling
        puppet-bolt
        # system tooling
        criu podman qemu
        # debugging
        gdb
        # games
        bsdgames
      ])
    ];

    documentation.dev.enable = true;
    documentation.nixos.enable = !config.benaryorg.base.lightweight;

    users.users.root =
    {
      subUidRanges = [ { startUid = 2000000; count = 1000000; } ];
      subGidRanges = [ { startGid = 2000000; count = 1000000; } ];
    };
  };
}
