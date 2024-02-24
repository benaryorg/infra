{ config, lib, options, ... }:
{
  options =
  {
    benaryorg.hardware =
    {
      vendor = lib.mkOption
      {
        default = "container";
        description = "Whether to enroll the default SSH user.";
        type = lib.types.enum [ "container" "ovh" "none" ];
      };
      ovh =
      {
        device = lib.mkOption
        {
          description = lib.mdDoc "List of devices and their UUIDs, each **must** be GPT and have four partitions: 1) bios boot, 2) `/boot` (mdadm), 3) lukskey (1 sector), 4) luksroot (btrfs).";
          type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
          example = lib.literalExpression
          ''
            device =
            {
              sda =
              {
                # sda4 (luks encrypted partition) has this uuid
                uuid = "05208d0f-61a9-4ab4-968e-ae1a4dfbf382";
                # sda3 is the luks key and has this partuuid
                keyuuid = "817bbe88-c6db-4cbd-8c67-0e9aac92e067";
              }
              # sdb4 (luks encrypted partition) has this uuid, sdb3 is the key
              sdb =
              {
                uuid = "bb8e805b-52d9-4c03-848e-e57f3b364a41";
                keyuuid = "09b7135d-0902-4bf5-80e7-b6de7995b06b";
              };
            };
          '';
        };
        fs =
        {
          boot = lib.mkOption
          {
            description = lib.mdDoc "UUID of `/boot` (ext4).";
            type = lib.types.str;
          };
          root = lib.mkOption
          {
            description = "UUID of rootfs (btrfs).";
            type = lib.types.str;
          };
        };
        kernelModules = lib.mkOption
        {
          default = [ "uhci_hcd" "ehci_pci" "ahci" "sd_mod" ];
          description = "List of kernel modules.";
          type = lib.types.listOf lib.types.str;
        };
        filesystems = lib.mkOption
        {
          default = [ "ext4" "btrfs" ];
          description = "List of filesystems.";
          type = lib.types.listOf lib.types.str;
        };
        btrfsScrub = lib.mkOption
        {
          default = [ "/" ];
          description = "List of filesystems to scrub (empty will disable scrubbing).";
          type = lib.types.listOf lib.types.str;
        };
      };
    };
  };

  config = lib.mkMerge
    [
      {
        benaryorg.deployment.tags = lib.mkAfter [ config.benaryorg.hardware.vendor ];
      }
      (
        let
          udevRules =
          ''
            ACTION=="add|change", KERNEL=="[sv]d[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
          '';
        in
          {
            boot.initrd.services.udev.rules = udevRules;
            services.udev.extraRules = udevRules;
          }
      )
      (lib.mkIf (config.benaryorg.hardware.vendor == "container")
      {
        systemd.oomd.enable = false;
        # remainder of the container configuration is stolen from
        # <nixpkgs/nixos/modules/virtualisation/lxc-container.nix>
        boot.isContainer = true;
        boot.postBootCommands =
        ''
          # After booting, register the contents of the Nix store in the Nix
          # database.
          if [ -f /nix-path-registration ]; then
            ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration &&
            rm /nix-path-registration
          fi

          # nixos-rebuild also requires a "system" profile
          ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
        '';
        systemd.extraConfig =
        ''
          [Service]
          ProtectProc=default
          ProtectControlGroups=no
          ProtectKernelTunables=no
        '';
        system.activationScripts.installInitScript = lib.mkForce
        ''
          ln -fs $systemConfig/init /sbin/init
        '';
        boot.specialFileSystems."/run".options = [ "rshared" ];
      })
      (lib.mkIf (config.benaryorg.hardware.vendor != "container")
      {
        boot.kernel.sysctl =
        {
          "kernel.sysrq" = 244;
          "kernel.panic" = 3;
          "fs.protected_symlinks" = 1;
          "fs.protected_hardlinks" = 1;
          "net.core.rmem_max" = 4194304;
          "net.core.wmem_max" = 1048576;
        };
        benaryorg.prometheus.client.exporters.smartctl.enable = true;
      })
      (lib.mkIf (config.benaryorg.hardware.vendor == "ovh")
      {
        boot.kernelParams = [ "console=ttyS0,115200" ];
        boot.loader.grub =
        {
          enable = true;
          devices = lib.pipe config.benaryorg.hardware.ovh.device [ builtins.attrNames (builtins.map (name: "/dev/${name}")) ];
          splashImage = null;
        };
        swapDevices = lib.mkDefault [];
        boot.initrd.availableKernelModules = config.benaryorg.hardware.ovh.kernelModules;
        boot.initrd.supportedFilesystems = config.benaryorg.hardware.ovh.filesystems;
        boot.supportedFilesystems = config.benaryorg.hardware.ovh.filesystems;
        hardware.cpu.intel.updateMicrocode = true;

        boot.swraid =
        {
          enable = true;
          mdadmConf = "MAILADDR root@benary.org";
        };

        services =
        {
          openntpd.enable = true;
          fstrim.enable = true;
          btrfs.autoScrub =
          {
            enable = config.benaryorg.hardware.ovh.btrfsScrub != [];
            fileSystems = config.benaryorg.hardware.ovh.btrfsScrub;
            interval = "weekly";
          };
        };

        boot.initrd.luks.devices =
          let
            device = name: data:
            {
              "luks-${data.uuid}" =
              {
                device = "/dev/disk/by-uuid/${data.uuid}";
                allowDiscards = true;
                fallbackToPassword = false;
                keyFile = "/dev/disk/by-partuuid/${data.keyuuid}";
              };
            };
            luksDevices = (lib.flip lib.pipe) [ (lib.mapAttrsToList device) (builtins.foldl' (a: b: a // b) {}) ];
          in
            luksDevices config.benaryorg.hardware.ovh.device;

        fileSystems =
        {
          "/" =
          {
            device = "/dev/disk/by-uuid/${config.benaryorg.hardware.ovh.fs.root}";
            fsType = "btrfs";
            options = [ "noatime" "compress=zstd" "degraded" "space_cache=v2" "subvol=@" "discard=async" ];
          };
          "/boot" =
          {
            device = "/dev/disk/by-uuid/${config.benaryorg.hardware.ovh.fs.boot}";
            fsType = "ext4";
            options = [ "noatime" "discard" ];
          };
        };
      })
    ];
}
