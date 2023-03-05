{
  inputs =
  {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    ragenix.url = "github:yaxitech/ragenix";
  };

  outputs = { nixpkgs, ragenix, ... }:
  {
    colmena =
    {
      meta =
      {
        nixpkgs = import nixpkgs
        {
          system = "x86_64-linux";
        };
        specialArgs =
        {
          inherit ragenix;
        };
      };

      defaults = { name, nodes, pkgs, lib, config, options, ... }:
        let
          conf = pkgs.callPackage ./conf {};
        in
          with lib;
          {
            imports =
            [
              ragenix.nixosModules.default
              ./spec/user.nix
              ./spec/ssh.nix
              ./spec/nix.nix
              ./spec/hardware.nix
              ./spec/base.nix
              ./spec/git.nix
              ./spec/net.nix
            ];

            options =
            {
              benaryorg.deployment =
              {
                default = mkOption
                {
                  default = true;
                  description = "Whether to add the host to the @default deployment.";
                  type = types.bool;
                };
              };
            };

            config =
            {
              deployment =
              {
                targetHost = name;
                targetUser = conf.sshuser;
                tags = [ config.benaryorg.hardware.vendor (mkIf config.benaryorg.deployment.default "default")];
                buildOnTarget = true;
              };
              benaryorg.user.ssh.keys = [ (getAttrFromPath [ "sshkey" "benaryorg@shell.cloud.bsocat.net" ] conf) ];
            };
          };

      "shell.cloud.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              deployment.allowLocalDeployment = true;

              benaryorg.base.sudo.needsPassword = true;
              benaryorg.deployment.default = false;
              benaryorg.git.adminkey = conf.sshkey."benaryorg@gnutoo.home.bsocat.net";
              benaryorg.git.enable = true;
              benaryorg.hardware.vendor = "ovh";
              benaryorg.ssh.x11 = true;
              benaryorg.user.ssh.keys = pkgs.lib.attrValues conf.sshkey;

              networking.interfaces =
              {
                eno0 =
                {
                  ipv4 =
                  {
                    addresses = [ { address = "151.80.37.166"; prefixLength = 24; } ];
                    routes = [ { address = "0.0.0.0"; prefixLength = 0; via = "151.80.37.254"; } ];
                  };
                  ipv6 =
                  {
                    addresses = [ { address = "2001:41d0:e:a10:6d4a:9111:c458:87f1"; prefixLength = 56; } ];
                    routes = [ { address = "::"; prefixLength = 0; via = "2001:41d0:e:aff:ff:ff:ff:fd"; } ];
                  };
                };
              };
              fileSystems =
              {
                "/boot" =
                {
                  device = "/dev/disk/by-uuid/cb5c4f14-eca6-484e-b021-28487094a0a1";
                  fsType = "ext4";
                  options = [ "noatime" "discard" ];
                };
                "/" =
                {
                  device = "/dev/disk/by-uuid/97bacf4c-ff7a-40f6-9581-b490977d185f";
                  fsType = "btrfs";
                  options = [ "subvol=@" "noatime" "degraded" "compress=zstd" "discard=async" "space_cache=v2" ];
                };
              };
              boot.initrd.luks.devices.root =
              {
                device = "/dev/disk/by-uuid/cf591bea-156c-4094-92a3-814c8f67e37e";
                allowDiscards = true;
                fallbackToPassword = false;
                keyFile = "/dev/sda3";
              };
            };

      "nixos.home.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              benaryorg.ssh.x11 = true;
              benaryorg.user.ssh.keys = [ conf.sshkey."benaryorg@shell.cloud.bsocat.net" conf.sshkey."benaryorg@gnutoo.home.bsocat.net" ];

              networking.nameservers = [ "2a01:4f8:1c17:a0a9:20e:c4ff:fed0:6a79" ];
            };

      "lxd6.cloud.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              benaryorg.hardware.vendor = "ovh";
              benaryorg.hardware.ovh.bootDevices = [ "/dev/sda" "/dev/sdb" ];

              networking.interfaces =
              {
                eno1 =
                {
                  ipv4 =
                  {
                    addresses = [ { address = "37.187.145.124"; prefixLength = 24; } ];
                    routes = [ { address = "0.0.0.0"; prefixLength = 0; via = "37.187.145.254"; } ];
                  };
                  ipv6 =
                  {
                    addresses = [ { address = "2001:41d0:a:517c::1"; prefixLength = 56; } ];
                    routes = [ { address = "::"; prefixLength = 0; via = "2001:41d0:a:51ff:ff:ff:ff:ff"; } ];
                  };
                };
              };
              fileSystems =
              {
                "/" =
                {
                  device = "/dev/disk/by-uuid/87967ab0-05c9-4d4d-9873-90bb10233a69";
                  fsType = "btrfs";
                  options = [ "noatime" "compress=zstd" "degraded" "space_cache=v2" "subvol=@" "discard=async" ];
                };
                "/boot" =
                {
                  device = "/dev/disk/by-uuid/4726bb92-3b08-4026-b557-7a7da7491ba0";
                  fsType = "ext4";
                  options = [ "noatime" "discard" ];
                };
              };

              boot.initrd.luks.devices =
              {
                "root-a" =
                {
                  device = "/dev/disk/by-uuid/6fbaef44-b179-43f3-88ca-8e5f1bc3c3f0";
                  allowDiscards = true;
                  fallbackToPassword = false;
                  keyFile = "/dev/sda3";
                };
                "root-b" =
                {
                  device = "/dev/disk/by-uuid/fa938535-0599-458b-9ff8-55f7f41eff6f";
                  allowDiscards = true;
                  fallbackToPassword = false;
                  keyFile = "/dev/sdb3";
                };
              };
            };
    };
  };
}
