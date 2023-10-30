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
      lightweight = mkOption
      {
        default = false;
        description = "Enabling this will remove some larger packages.";
        type = types.bool;
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
    systemd.services.nginx.unitConfig.StartLimitIntervalSec = mkDefault 300;

    systemd.extraConfig =
    ''
      DefaultRestartSec=1
      DefaultStartLimitIntervalSec=300
      DefaultStartLimitBurst=60
    '';

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
      ssh.knownHosts =
        let
          globalConf = pkgs.callPackage ../conf {};
          hostkey = globalConf.hostkey;
          toKnownHost = _: value: { publicKey = value; };
        in
          builtins.mapAttrs toKnownHost hostkey;
    };

    services =
    {
      lldpd.enable = true;
      atd.enable = true;
      locate =
      {
        enable = true;
        interval = "daily";
        locate = pkgs.mlocate;
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
        colmena ragenix.packages.${pkgs.stdenv.system}.default nix-diff
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
