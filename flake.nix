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

      defaults = { name, nodes, pkgs, lib, config, ... }:
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

            deployment =
            {
              targetHost = name;
              targetUser = conf.sshuser;
              tags = [ config.benaryorg.hardware.vendor ];
              buildOnTarget = true;
            };
            benaryorg.user.ssh.keys = [ (getAttrFromPath [ "sshkey" "benaryorg@shell.cloud.bsocat.net" ] conf) ];
          };

      "shell.cloud.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              deployment.allowLocalDeployment = true;

              benaryorg.base.sudo.needsPassword = true;
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
    };
  };
}
