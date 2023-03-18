{
  inputs =
  {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgsSyncplay.url = "github:NixOS/nixpkgs?rev=cd0f6e59d17d337f398bbef85636e75089b0f9e8";
    ragenix.url = "github:yaxitech/ragenix";
  };

  outputs = { nixpkgs, ragenix, nixpkgsSyncplay, ... }:
  {
    colmena =
    {
      meta =
      {
        nixpkgs = import nixpkgs
        {
          system = "x86_64-linux";
        };
        nodeNixpkgs =
        {
          "syncplay.lxd.bsocat.net" = import nixpkgsSyncplay
          {
            system = "x86_64-linux";
          };
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
              ./spec/nullmailer.nix
              ./spec/hardware.nix
              ./spec/base.nix
              ./spec/git.nix
              ./spec/net.nix
              ./spec/lxd.nix
              ./spec/prometheus.nix
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
                tags = [ (mkIf config.benaryorg.deployment.default "default")];
                buildOnTarget = true;
              };
              benaryorg.user.ssh.keys = [ (getAttrFromPath [ "sshkey" "benaryorg@shell.cloud.bsocat.net" ] conf) ];
              security.acme.acceptTerms = true;
              security.acme.defaults.email = "letsencrypt@benary.org";
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

      "lxd1.cloud.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.lxdLegoSecret.file = ./secret/lego/hedns/lxd1.cloud.bsocat.net.age;
              benaryorg.hardware.vendor = "ovh";
              benaryorg.lxd.enable = true;
              benaryorg.lxd.cluster = "lxd.bsocat.net";
              benaryorg.lxd.legoConfig =
              {
                dnsProvider = "hurricane";
                credentialsFile = config.age.secrets.lxdLegoSecret.path;
              };
              benaryorg.net.host.primaryInterface = "eno1";
              benaryorg.net.host.ipv4 = "94.23.38.16/24";
              benaryorg.net.host.ipv4Gateway = "94.23.38.254";
              benaryorg.net.host.ipv6 = "2001:41d0:2:2710::1/56";
              benaryorg.net.host.ipv6Gateway = "2001:41d0:2:27ff:ff:ff:ff:ff";
              benaryorg.hardware.ovh =
              {
                device =
                {
                  sda = { uuid = "7bf4045c-6a00-4692-9c20-5a7f44dc085c"; keyuuid = "1d772c63-594e-144b-bbb2-18956c84c998"; };
                  sdb = { uuid = "a72e9fb2-454c-4ca7-b6c7-a5d1d975832a"; keyuuid = "d497d602-36a8-7549-9127-014241c0a535"; };
                };
                fs =
                {
                  root = "daa52a9d-e14d-43b4-befa-a18c6225dd7f";
                  boot = "9d48e3b9-ef76-48b8-969a-266cf0b76be1";
                };
              };
            };

      "lxd2.cloud.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.lxdLegoSecret.file = ./secret/lego/hedns/lxd2.cloud.bsocat.net.age;
              benaryorg.hardware.vendor = "ovh";
              benaryorg.lxd.enable = true;
              benaryorg.lxd.cluster = "lxd.bsocat.net";
              benaryorg.lxd.legoConfig =
              {
                dnsProvider = "hurricane";
                credentialsFile = config.age.secrets.lxdLegoSecret.path;
              };
              benaryorg.net.host.primaryInterface = "eno1";
              benaryorg.net.host.ipv4 = "37.187.8.147/24";
              benaryorg.net.host.ipv4Gateway = "37.187.8.254";
              benaryorg.net.host.ipv6 = "2001:41d0:a:893::1/56";
              benaryorg.net.host.ipv6Gateway = "2001:41d0:a:8ff:ff:ff:ff:ff";
              benaryorg.hardware.ovh =
              {
                device =
                {
                  sda = { uuid = "d7e0b6a4-b4d2-4a69-a103-2a2299ca72b2"; keyuuid = "e91250a9-a575-9a48-98e3-8d07672d7f21"; };
                };
                fs =
                {
                  root = "dd4353e5-fbea-4906-a694-e9a7cb1b4679";
                  boot = "f13918cc-9ac3-4c86-a221-87805beaa80d";
                };
              };
            };

      "lxd3.cloud.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.lxdLegoSecret.file = ./secret/lego/hedns/lxd3.cloud.bsocat.net.age;
              benaryorg.hardware.vendor = "ovh";
              benaryorg.lxd.enable = true;
              benaryorg.lxd.cluster = "lxd.bsocat.net";
              benaryorg.lxd.legoConfig =
              {
                dnsProvider = "hurricane";
                credentialsFile = config.age.secrets.lxdLegoSecret.path;
              };
              benaryorg.net.host.primaryInterface = "eno1";
              benaryorg.net.host.ipv4 = "198.100.145.227/24";
              benaryorg.net.host.ipv4Gateway = "198.100.145.254";
              benaryorg.net.host.ipv6 = "2607:5300:60:8e3::1/56";
              benaryorg.net.host.ipv6Gateway = "2607:5300:60:8ff:ff:ff:ff:ff";
              benaryorg.hardware.ovh =
              {
                device =
                {
                  sda = { uuid = "ba52e296-4b0b-4d6f-86af-e3c133b59375"; keyuuid = "f6847590-dbb8-4940-9986-bbceedb58b46"; };
                };
                fs =
                {
                  root = "694e3cbd-20ee-4b39-a768-47dcf7df1373";
                  boot = "62c57898-8398-49ce-ad3b-198ab2299b46";
                };
              };
            };

      "lxd4.cloud.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.lxdLegoSecret.file = ./secret/lego/hedns/lxd4.cloud.bsocat.net.age;
              benaryorg.hardware.vendor = "ovh";
              benaryorg.lxd.enable = true;
              benaryorg.lxd.cluster = "lxd.bsocat.net";
              benaryorg.lxd.legoConfig =
              {
                dnsProvider = "hurricane";
                credentialsFile = config.age.secrets.lxdLegoSecret.path;
              };
              benaryorg.net.host.primaryInterface = "enp3s0";
              benaryorg.net.host.ipv4 = "37.187.89.188/24";
              benaryorg.net.host.ipv4Gateway = "37.187.89.254";
              benaryorg.net.host.ipv6 = "2001:41d0:a:31bc::1/56";
              benaryorg.net.host.ipv6Gateway = "2001:41d0:a:31ff:ff:ff:ff:ff";
              benaryorg.hardware.ovh =
              {
                device =
                {
                  sda = { uuid = "e8d33298-8829-4720-95a9-65bc1f0d630c"; keyuuid = "80334940-bad4-1645-9d7f-e3f0306c7e6d"; };
                  sdb = { uuid = "50f61ebd-9a6c-4a3e-afb5-39821081502c"; keyuuid = "054beafa-d039-e848-a9c7-e07d40bf6194"; };
                };
                fs =
                {
                  root = "c0096bb8-9a5d-4df8-8fbe-e0f693d8e74f";
                  boot = "1ae61624-fef8-4555-80d0-514e7ba1cb47";
                };
              };
            };

      "lxd5.cloud.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              benaryorg.deployment.default = false;
              benaryorg.lxd.enable = true;
              benaryorg.lxd.cluster = "lxd.bsocat.net";
            };

      "lxd6.cloud.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.lxdLegoSecret.file = ./secret/lego/hedns/lxd6.cloud.bsocat.net.age;
              benaryorg.hardware.vendor = "ovh";
              benaryorg.lxd.enable = true;
              benaryorg.lxd.cluster = "lxd.bsocat.net";
              benaryorg.lxd.legoConfig =
              {
                dnsProvider = "hurricane";
                credentialsFile = config.age.secrets.lxdLegoSecret.path;
              };
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

      "steam.lxd.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              benaryorg.user.ssh.keys = [ (getAttrFromPath [ "sshkey" "benaryorg@gnutoo.home.bsocat.net" ] conf) ];
              benaryorg.ssh.x11 = true;
            };

      "syncplay.lxd.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.syncplaySalt.file = ./secret/service/syncplay/syncplay.lxd.bsocat.net.age;
              users.groups.syncplay = {};
              users.users.syncplay =
              {
                isSystemUser = true;
                group = "syncplay";
              };
              services.syncplay =
              {
                enable = true;
                saltFile = config.age.secrets.syncplaySalt.path;
                certDir = "/run/credentials/syncplay.service";
                user = "syncplay";
                group = "syncplay";
                extraArgs = [ "--isolate-rooms" ];
              };
              security.acme.certs."${config.networking.fqdn}" =
              {
                reloadServices = [ "syncplay.service" ];
                listenHTTP = ":80";
                group = "syncplay";
              };
              systemd.services.syncplay =
              {
                wants = [ "acme-finished-${config.networking.fqdn}.target" ];
                after = [ "acme-finished-${config.networking.fqdn}.target" ];
                serviceConfig.LoadCredential =
                [
                  "cert.pem:/var/lib/acme/${config.networking.fqdn}/cert.pem"
                  "privkey.pem:/var/lib/acme/${config.networking.fqdn}/key.pem"
                  "chain.pem:/var/lib/acme/${config.networking.fqdn}/chain.pem"
                ];
              };
            };
    };
  };
}
