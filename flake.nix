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
              benaryorg.net.host.primaryInterface = "eno0";
              benaryorg.net.host.ipv4 = "151.80.37.166/24";
              benaryorg.net.host.ipv4Gateway = "151.80.37.254";
              benaryorg.net.host.ipv6 = "2001:41d0:e:a10:6d4a:9111:c458:87f1/56";
              benaryorg.net.host.ipv6Gateway = "2001:41d0:e:aff:ff:ff:ff:ff";
              benaryorg.hardware.ovh =
              {
                device =
                {
                  sda = { uuid = "cf591bea-156c-4094-92a3-814c8f67e37e"; keyuuid = "6b7e5660-673e-a24f-af18-a515af4c857c"; };
                };
                fs =
                {
                  root = "97bacf4c-ff7a-40f6-9581-b490977d185f";
                  boot = "cb5c4f14-eca6-484e-b021-28487094a0a1";
                };
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
              benaryorg.net.host.primaryInterface = "eno1";
              benaryorg.net.host.ipv4 = "37.187.145.124/24";
              benaryorg.net.host.ipv4Gateway = "37.187.145.254";
              benaryorg.net.host.ipv6 = "2001:41d0:a:517c::1/56";
              benaryorg.net.host.ipv6Gateway = "2001:41d0:a:51ff:ff:ff:ff:ff";
              benaryorg.hardware.ovh =
              {
                device =
                {
                  sda = { uuid = "6fbaef44-b179-43f3-88ca-8e5f1bc3c3f0"; keyuuid = "5a2aaeea-6981-6b4d-91c4-61dcaa8cb12e"; };
                  sdb = { uuid = "fa938535-0599-458b-9ff8-55f7f41eff6f"; keyuuid = "a5f0c623-ee37-5e4e-a78d-a4271a0c4b04"; };
                };
                fs =
                {
                  root = "ea9ea296-44d8-43f2-9ceb-1c765b1b1b7d";
                  boot = "eaa28e6d-63df-46c6-9a13-652b6c0a5ce4";
                };
              };
            };
    };
  };
}
