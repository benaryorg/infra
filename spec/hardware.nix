{ nixpkgs, config, pkgs, lib, options, ... }:
with lib;
{
  options =
  {
    benaryorg.hardware =
    {
      vendor = mkOption
      {
        default = "container";
        description = "Whether to enroll the default SSH user.";
        type = types.enum [ "container" "ovh" ];
      };
      ovh =
      {
        bootDevices = mkOption
        {
          default = [ "/dev/sda" ];
          description = "List of boot devices for grub.";
          type = types.listOf types.str;
        };
        kernelModules = mkOption
        {
          default = [ "uhci_hcd" "ehci_pci" "ahci" "sd_mod" ];
          description = "List of kernel modules.";
          type = types.listOf types.str;
        };
        filesystems = mkOption
        {
          default = [ "ext4" "btrfs" ];
          description = "List of filesystems.";
          type = types.listOf types.str;
        };
        btrfsScrub = mkOption
        {
          default = [ "/" ];
          description = "List of filesystems to scrub (empty will disable scrubbing).";
          type = types.listOf types.str;
        };
      };
    };
  };

  config = mkMerge
    [
      (mkIf (config.benaryorg.hardware.vendor == "container")
      {
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
        system.activationScripts.installInitScript = mkForce
        ''
          ln -fs $systemConfig/init /sbin/init
        '';
      })
      (mkIf (config.benaryorg.hardware.vendor == "ovh")
      {
        boot.kernelParams = [ "console=ttyS0,115200" ];
        boot.loader.grub =
        {
          enable = true;
          version = 2;
          devices = config.benaryorg.hardware.ovh.bootDevices;
          splashImage = null;
        };
        swapDevices = mkDefault [];
        boot.initrd.availableKernelModules = config.benaryorg.hardware.ovh.kernelModules;
        boot.initrd.supportedFilesystems = config.benaryorg.hardware.ovh.filesystems;
        boot.supportedFilesystems = config.benaryorg.hardware.ovh.filesystems;
        hardware.cpu.intel.updateMicrocode = true;

        services =
        {
          openntpd.enable = true;
          btrfs.autoScrub =
          {
            enable = config.benaryorg.hardware.ovh.btrfsScrub != [];
            fileSystems = config.benaryorg.hardware.ovh.btrfsScrub;
          };
        };
      })
    ];
}
