{
  inputs =
  {
    nixpkgs.url = "git+https://git.shell.bsocat.net/nixpkgs?ref=nixos-23.05";
    nixpkgs-unstable.url = "git+https://git.shell.bsocat.net/nixpkgs?ref=nixos-unstable";
    ragenix.url = "git+https://git.shell.bsocat.net/ragenix";
    ragenix.inputs.nixpkgs.follows = "nixpkgs-unstable";
    ragenix.inputs.agenix.follows = "agenix";
    ragenix.inputs.flake-utils.follows = "flake-utils";
    ragenix.inputs.rust-overlay.follows = "rust-overlay";
    ragenix.inputs.crane.follows = "crane";
    colmena.url = "git+https://git.shell.bsocat.net/colmena";
    colmena.inputs.nixpkgs.follows = "nixpkgs";
    colmena.inputs.stable.follows = "nixpkgs";
    colmena.inputs.flake-compat.follows = "flake-compat";
    colmena.inputs.flake-utils.follows = "flake-utils";
    agenix.url = "git+https://git.shell.bsocat.net/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";
    agenix.inputs.darwin.follows = "darwin";
    flake-compat.url = "git+https://git.shell.bsocat.net/flake-compat";
    flake-compat.flake = false;
    flake-utils.url = "git+https://git.shell.bsocat.net/flake-utils";
    flake-utils.inputs.systems.follows = "nix-systems";
    rust-overlay.url = "git+https://git.shell.bsocat.net/rust-overlay";
    rust-overlay.inputs.flake-utils.follows = "flake-utils";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    benaryorg-website.url = "git+https://git.shell.bsocat.net/benary.org";
    benaryorg-website.inputs.flake-utils.follows = "flake-utils";
    benaryorg-website.inputs.nixpkgs.follows = "nixpkgs";
    crane.url = "git+https://git.shell.bsocat.net/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    nix-systems.url = "git+https://git.shell.bsocat.net/nix-systems";
    home-manager.url = "git+https://git.shell.bsocat.net/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "git+https://git.shell.bsocat.net/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    lxddns.url = "git+https://git.shell.bsocat.net/lxddns";
    lxddns.inputs.nixpkgs.follows = "nixpkgs";
    lxddns.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { self, nixpkgs, colmena, ragenix, benaryorg-website, lxddns, ... }:
    let
      pkgs = import nixpkgs
      {
        system = "x86_64-linux";
      };
      colmenaConfig =
      {
        meta =
        {
          nixpkgs = pkgs;
          allowApplyAll = false;
        };

        defaults = { name, nodes, pkgs, lib, config, options, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              imports =
              [
                self.nixosModules.default
              ];
              config =
              {
                deployment =
                {
                  targetHost = name;
                  targetUser = conf.sshuser;
                  privilegeEscalationCommand = [ "sudo" "-H" "TMPDIR=/nix/tmp" "--" ];
                  tags = config.benaryorg.deployment.tags;
                  buildOnTarget = true;
                };
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
              benaryorg.flake.autoupgrade = false;
              benaryorg.build.role = "none";

              age.secrets.lxdLegoSecret.file = ./secret/lego/hedns/shell.cloud.bsocat.net.age;
              benaryorg.base.sudo.needsPassword = true;
              benaryorg.deployment.default = false;
              benaryorg.prometheus.client.enable = true;

              benaryorg.hardware.vendor = "ovh";
              benaryorg.ssh.x11 = true;
              benaryorg.user.ssh.keys = pkgs.lib.attrValues conf.sshkey;
              benaryorg.lxd.enable = true;
              benaryorg.lxd.cluster = "shell.bsocat.net";
              benaryorg.lxd.allowedUsers = [];
              benaryorg.lxd.legoConfig =
              {
                dnsProvider = "hurricane";
                credentialsFile = config.age.secrets.lxdLegoSecret.path;
                webroot = null;
              };

              zramSwap.enable = true;
              services.openssh.settings.MaxStartups = "50";
              # FIXME: shouldn't be required, potentially needs migration of the git repos over to a container
              users.users.nginx.extraGroups = [ "lxddns" ];

              services.nginx =
              {
                enable = true;
                recommendedTlsSettings = true;
                virtualHosts =
                {
                  ${config.networking.fqdn} =
                  {
                    forceSSL = true;
                    enableACME = true;
                    locations."/" = { return = "302 \"https://git.shell.bsocat.net\""; };
                  };
                };
              };

              benaryorg.net.host.primaryInterface = "enp1s0";
              benaryorg.net.host.ipv4 = "213.32.7.146/24";
              benaryorg.net.host.ipv4Gateway = "213.32.7.254";
              benaryorg.net.host.ipv6 = "2001:41d0:303:192::1/56";
              benaryorg.net.host.ipv6Gateway = "2001:41d0:303:1ff:ff:ff:ff:ff";
              benaryorg.hardware.ovh =
              {
                device =
                {
                  sda = { uuid = "7d05e9e8-fcd5-462f-be4f-ac6896092a15"; keyuuid = "f85d4432-b7fe-214c-a105-654a8d99d4ea"; };
                };
                fs =
                {
                  root = "897816a8-8ff3-494d-9579-55d7e766616c";
                  boot = "49e52b5d-3cbc-4318-9fd3-e362dac54dde";
                };
              };

              system.stateVersion = "23.05";
            };

        "nixos.home.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.buildSecret.file = ./secret/build/nixos.home.bsocat.net.age;
              benaryorg.net.type = "manual";
              benaryorg.ssh.x11 = true;
              benaryorg.user.ssh.keys = [ conf.sshkey."benaryorg@shell.cloud.bsocat.net" conf.sshkey."benaryorg@gnutoo.home.bsocat.net" ];
              benaryorg.prometheus.client.enable = true;

              benaryorg.build =
              {
                role = "server";
                publicKey = "nixos.home.bsocat.net:yiK6zWXrGJRUw2LqhSqr9x1H6jbeLl/nokgJJBVJZ80=";
                privateKeyFile = config.age.secrets.buildSecret.path;
              };

              networking.nameservers = [ "2a0c:b641:a40:5::" ];

              system.stateVersion = "23.05";
            };

        "radosgw1.home.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.homes3LegoSecret.file = ./secret/lego/hedns/home-s3.xn--idk5byd.net.acme.bsocat.net.age;
              benaryorg.net.type = "manual";
              benaryorg.user.ssh.keys = [ (getAttrFromPath [ "sshkey" "benaryorg@gnutoo.home.bsocat.net" ] conf) ];
              benaryorg.prometheus.client.enable = true;

              services =
              {
                ceph =
                {
                  enable = true;
                  global =
                  {
                    fsid = "62e93be0-0c5f-4e11-ab8c-e93376a40b87";
                    monHost = "v2:[2a0c:b641:a40::264b:feff:fe90:7474]:3301/0 v2:[2a0c:b641:a40::264b:feff:fe90:7474]:3302/0 v2:[2a0c:b641:a40::264b:feff:fe90:7474]:3303/0";

                    authClusterRequired = "cephx";
                    authServiceRequired = "cephx";
                    authClientRequired = "cephx";

                    publicNetwork = "2a0c:b641:a40::/48";
                    clusterNetwork = "2a0c:b641:a40::/48";
                  };

                  extraConfig =
                  {
                    ms_bind_ipv4 = "false";
                    ms_bind_ipv6 = "true";

                    ms_cluster_mode = "secure";
                    ms_service_mode = "secure";
                    ms_client_mode = "secure";
                    ms_mon_cluster_mode = "secure";
                    ms_mon_service_mode = "secure";
                    ms_mon_client_mode = "secure";
                    rbd_default_map_options = "ms_mode=secure";
                  };
                  client =
                  {
                    enable = true;
                    extraConfig =
                    {
                      "client.radosgw.1" =
                      {
                        rgw_frontends = "beast endpoint=[::1]:7480";
                        rgw_resolve_cname = "true";
                        rgw_dns_name = "home-s3.xn--idk5byd.net";
                      };
                    };
                  };
                  rgw =
                  {
                    enable = true;
                    daemons = [ "radosgw.1" ];
                  };
                };
                nginx =
                {
                  enable = true;
                  # includes proxy_http_version=1.1 (required by request_buffering)
                  recommendedProxySettings = true;
                  recommendedTlsSettings = true;
                  virtualHosts =
                  {
                    ${config.networking.fqdn} =
                    {
                      enableACME = true;
                      forceSSL = true;
                      locations."/" = { return = "200 \"Meow.\""; extraConfig = "more_set_headers 'content-type: text/plain';"; };
                    };
                    "home-s3.xn--idk5byd.net" =
                    {
                      serverAliases = [ "*.home-s3.xn--idk5byd.net" ];
                      enableACME = true;
                      forceSSL = true;
                      extraConfig =
                      ''
                        # avoids request size constraints/temporary files
                        proxy_buffering off;
                        proxy_request_buffering off;
                        client_max_body_size 0;
                      '';
                      locations."/" =
                      {
                        proxyPass = "http://localhost:7480";
                      };
                    };
                  };
                };
              };
              security.acme.certs."home-s3.xn--idk5byd.net" =
              {
                dnsProvider = "hurricane";
                credentialsFile = config.age.secrets.homes3LegoSecret.path;
                reloadServices = [ "nginx.service" ];
                group = config.services.nginx.group;
                webroot = null;
              };

              networking.nameservers = [ "2a0c:b641:a40:5::" ];

              system.stateVersion = "23.05";
            };

        "lxd1.cloud.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.lxdLegoSecret.file = ./secret/lego/hedns/lxd1.cloud.bsocat.net.age;
              benaryorg.prometheus.client.enable = true;
              benaryorg.hardware.vendor = "ovh";
              benaryorg.lxd.enable = true;
              benaryorg.lxd.cluster = "lxd.bsocat.net";
              benaryorg.lxd.legacySmtpProxy = true;
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

              system.stateVersion = "23.05";
            };

        "lxd2.cloud.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.lxdLegoSecret.file = ./secret/lego/hedns/lxd2.cloud.bsocat.net.age;
              benaryorg.prometheus.client.enable = true;
              benaryorg.hardware.vendor = "ovh";
              benaryorg.lxd.enable = true;
              benaryorg.lxd.cluster = "lxd.bsocat.net";
              benaryorg.lxd.legacySmtpProxy = true;
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

              system.stateVersion = "23.05";
            };

        "lxd3.cloud.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.lxdLegoSecret.file = ./secret/lego/hedns/lxd3.cloud.bsocat.net.age;
              benaryorg.prometheus.client.enable = true;
              benaryorg.hardware.vendor = "ovh";
              benaryorg.lxd.enable = true;
              benaryorg.lxd.cluster = "lxd.bsocat.net";
              benaryorg.lxd.legacySmtpProxy = true;
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

              system.stateVersion = "23.05";
            };

        "lxd4.cloud.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.lxdLegoSecret.file = ./secret/lego/hedns/lxd4.cloud.bsocat.net.age;
              benaryorg.prometheus.client.enable = true;
              benaryorg.hardware.vendor = "ovh";
              benaryorg.lxd.enable = true;
              benaryorg.lxd.cluster = "lxd.bsocat.net";
              benaryorg.lxd.legacySmtpProxy = true;
              benaryorg.lxd.legoConfig =
              {
                dnsProvider = "hurricane";
                credentialsFile = config.age.secrets.lxdLegoSecret.path;
              };
              benaryorg.net.host.primaryInterface = "enp1s0";
              benaryorg.net.host.ipv4 = "37.187.92.26/24";
              benaryorg.net.host.ipv4Gateway = "37.187.92.254";
              benaryorg.net.host.ipv6 = "2001:41d0:a:341a::1/56";
              benaryorg.net.host.ipv6Gateway = "2001:41d0:a:34ff:ff:ff:ff:ff";
              benaryorg.hardware.ovh =
              {
                device =
                {
                  sda = { uuid = "c584315c-0738-4918-864f-18c7cbc756c0"; keyuuid = "5ba91813-4643-244c-9774-d4766bb7a805"; };
                  sdb = { uuid = "706c9c32-741b-4dcb-8c5b-b22ad037f086"; keyuuid = "e3c763f4-5d28-4849-82d8-506f341e3a66"; };
                };
                fs =
                {
                  root = "306a9a07-947a-4e4d-be61-5b2f15410831";
                  boot = "bdee9321-64ae-4bf6-92b7-a76377b7f9f6";
                };
              };

              system.stateVersion = "23.05";
            };

        "lxd5.cloud.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.lxdLegoSecret.file = ./secret/lego/hedns/lxd5.cloud.bsocat.net.age;
              benaryorg.prometheus.client.enable = true;
              benaryorg.hardware.vendor = "ovh";
              benaryorg.lxd.enable = true;
              benaryorg.lxd.cluster = "lxd.bsocat.net";
              benaryorg.lxd.legacySmtpProxy = true;
              benaryorg.lxd.legoConfig =
              {
                dnsProvider = "hurricane";
                credentialsFile = config.age.secrets.lxdLegoSecret.path;
              };
              benaryorg.net.host.primaryInterface = "eno1";
              benaryorg.net.host.ipv4 = "192.99.12.118/24";
              benaryorg.net.host.ipv4Gateway = "192.99.12.254";
              benaryorg.net.host.ipv6 = "2607:5300:60:3d76::1/56";
              benaryorg.net.host.ipv6Gateway = "2607:5300:60:3dff:ff:ff:ff:ff";
              benaryorg.hardware.ovh =
              {
                device =
                {
                  sda = { uuid = "64b37fa9-981c-42b7-b67e-c0d283270306"; keyuuid = "5283db23-c3b3-2d48-b633-faff893c99f1"; };
                };
                fs =
                {
                  root = "2919e656-e9e6-4fa5-8699-f2a0b7677a59";
                  boot = "b51fb8bd-b5b6-4b94-8e5e-51c90faa2b0d";
                };
              };

              system.stateVersion = "23.05";
            };

        "lxd6.cloud.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.lxdLegoSecret.file = ./secret/lego/hedns/lxd6.cloud.bsocat.net.age;
              benaryorg.prometheus.client.enable = true;
              benaryorg.hardware.vendor = "ovh";
              benaryorg.lxd.enable = true;
              benaryorg.lxd.cluster = "lxd.bsocat.net";
              benaryorg.lxd.legacySmtpProxy = true;
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

              system.stateVersion = "23.05";
            };

        "steam.lxd.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              benaryorg.user.ssh.keys = [ (getAttrFromPath [ "sshkey" "benaryorg@gnutoo.home.bsocat.net" ] conf) ];
              benaryorg.ssh.x11 = true;
              hardware.opengl.enable = true;
              benaryorg.prometheus.client.enable = true;
              security.acme.certs.${config.networking.fqdn}.listenHTTP = ":80";
              systemd.network.networks."40-ipv4".enable = lib.mkForce false;

              system.stateVersion = "23.05";
            };

        "syncplay.lxd.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.syncplaySalt =
              {
                file = ./secret/service/syncplay/syncplay.lxd.bsocat.net.age;
                owner = "syncplay";
              };

              benaryorg.prometheus.client.enable = true;
              users.groups.syncplay = {};
              users.users.syncplay =
              {
                isSystemUser = true;
                group = "syncplay";
                home = "/var/lib/syncplay";
                createHome = false;
              };
              services.syncplay =
              {
                enable = true;
                certDir = "/run/credentials/syncplay.service";
                user = "syncplay";
                group = "syncplay";
                extraArgs = [ "--isolate-rooms" ];
                saltFile = config.age.secrets.syncplaySalt.path;
              };
              security.acme.certs.${config.networking.fqdn} =
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
              systemd.tmpfiles.rules = [ "v '/var/lib/syncplay' 0750 syncplay syncplay - -" ];

              system.stateVersion = "23.05";
            };

        "prometheus.lxd.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.grafanaUser = { file = ./secret/service/grafana/prometheus.lxd.bsocat.net/admin_user.age; owner = "grafana"; mode = "0400"; };
              age.secrets.grafanaPass = { file = ./secret/service/grafana/prometheus.lxd.bsocat.net/admin_pass.age; owner = "grafana"; mode = "0400"; };
              age.secrets.grafanaSecret = { file = ./secret/service/grafana/prometheus.lxd.bsocat.net/secret.age; owner = "grafana"; mode = "0400"; };
              age.secrets.xmppAlerting = { file = ./secret/service/xmpp/xmpp.lxd.bsocat.net/user/benary.org/monitoring.age; };
              benaryorg.prometheus.server.enable = true;
              benaryorg.prometheus.client.enable = true;
              services =
              {
                prometheus =
                {
                  retentionTime = "360d";
                  xmpp-alerts =
                  {
                    enable = true;
                    settings =
                    {
                      jid = "monitoring@benary.org";
                      password_command = "cat \"\${CREDENTIALS_DIRECTORY}/password\"";
                      to_jid = "binary@benary.org";
                      listen_address = "::1";
                      listen_port = 9199;
                      text_template =
                      ''
                        *{{ status.upper() }}* ( `{{ endsAt if status.upper() == "RESOLVED" else startsAt }}` ): _{{ labels.host or labels.instance }}_ ({{ labels.alertname }}): {{ annotations.description or annotations.summary }}
                        {{ generatorURL }}
                      '';
                    };
                  };
                };
                grafana =
                {
                  enable = true;
                  settings =
                  {
                    database.wal = true;
                    security =
                    {
                      admin_user = "$__file{/run/agenix/grafanaUser}";
                      admin_password = "$__file{/run/agenix/grafanaPass}";
                      secret_key = "$__file{/run/agenix/grafanaSecret}";
                    };
                    server =
                    {
                      http_addr = "127.0.0.1";
                      http_port = 3000;
                      domain = config.networking.fqdn;
                      root_url = "https://${config.networking.fqdn}/";
                    };
                    analytics.reporting_enabled = false;
                    feature_toggles.publicDashboards = true;
                  };
                  declarativePlugins = with pkgs.grafanaPlugins; [ grafana-piechart-panel ];
                  provision =
                  {
                    enable = true;
                    datasources.settings =
                    {
                      datasources =
                      [
                        {
                          name = "Prometheus";
                          type = "prometheus";
                          url = "http://localhost:9090";
                          isDefault = true;
                          jsonData =
                          {
                            prometheusType = "Prometheus";
                          };
                        }
                      ];
                    };
                  };
                };
                nginx =
                {
                  enable = true;
                  recommendedProxySettings = true;
                  recommendedTlsSettings = true;
                  virtualHosts.${config.networking.fqdn} =
                  {
                    enableACME = true;
                    forceSSL = true;
                    locations."/" =
                    {
                      proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}/";
                      proxyWebsockets = true;
                    };
                  };
                };
              };
              systemd.services.prometheus-xmpp-alerts.serviceConfig.LoadCredential = [ "password:${config.age.secrets.xmppAlerting.path}" ];

              system.stateVersion = "23.05";
            };

        "xmpp.lxd.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.prosodyLegoSecret.file = ./secret/service/prosody/xmpp.lxd.bsocat.net.age;
              age.secrets.coturnSecret =
              {
                file = ./secret/service/coturn/turn.lxd.bsocat.net.age;
                owner = config.services.prosody.user;
              };
              benaryorg.prometheus.client.enable = true;
              benaryorg.prometheus.client.mocks.prosody =
              {
                port = 15280;
              };
              security.acme.certs =
              {
                ${config.networking.fqdn} =
                {
                  listenHTTP = ":80";
                  reloadServices = [ "prosody.service" ];
                  group = config.services.prosody.group;
                };
                "benary.org" =
                {
                  dnsProvider = "hurricane";
                  credentialsFile = config.age.secrets.prosodyLegoSecret.path;
                  reloadServices = [ "prosody.service" ];
                  group = config.services.prosody.group;
                  extraDomainNames = [ "conference.benary.org" ];
                };
              };
              services =
              {
                prosody =
                {
                  enable = true;
                  admins = [ "binary@benary.org" ];
                  allowRegistration = false;
                  authentication = "internal_hashed";
                  c2sRequireEncryption = true;
                  s2sRequireEncryption = true;
                  s2sSecureAuth = true;
                  extraConfig =
                  ''
                    unbound = {
                      resolvconf = true;
                    };
                    external_service_secret = io.open("${config.age.secrets.coturnSecret.path}","r"):read()
                    external_services = {
                      { type = "stun", host = "turn.svc.benary.org", port = 3478 },
                      { type = "turn", host = "turn.svc.benary.org", port = 3478, transport = "udp", secret = true, ttl = 86400, algorithm = "turn" },
                      { type = "turns", host = "turn.svc.benary.org", port = 5349, transport = "tcp", secret = true, ttl = 86400, algorithm = "turn" },
                      { type = "stun", host = "turn4.svc.benary.org", port = 3478 },
                      { type = "turn", host = "turn4.svc.benary.org", port = 3478, transport = "udp", secret = true, ttl = 86400, algorithm = "turn" },
                      { type = "turns", host = "turn4.svc.benary.org", port = 5349, transport = "tcp", secret = true, ttl = 86400, algorithm = "turn" },
                      { type = "stun", host = "turn6.svc.benary.org", port = 3478 },
                      { type = "turn", host = "turn6.svc.benary.org", port = 3478, transport = "udp", secret = true, ttl = 86400, algorithm = "turn" },
                      { type = "turns", host = "turn6.svc.benary.org", port = 5349, transport = "tcp", secret = true, ttl = 86400, algorithm = "turn" },
                    }

                    -- FIXME: prosody cannot be convinced to do SNI for both the hostname and the virtualhosts
                    -- it will send connection refused for the virtualhost's domains under some circumstances
                    -- to sum up my experience: prosody *really* wants you to use their certmanager which.… No.
                    --c2s_direct_tls_ports = { 5223, }
                    --s2s_direct_tls_ports = { 5270, }

                    http_max_content_size = 1024 * 1024 * 1024
                    statistics = "internal"
                    statistics_interval = "manual"
                  '';
                  ssl = { cert = "/var/lib/acme/${config.networking.fqdn}/cert.pem"; key = "/var/lib/acme/${config.networking.fqdn}/key.pem"; };
                  virtualHosts = mkForce
                  {
                    "benary.org" =
                    {
                      enabled = true;
                      domain = "benary.org";
                      ssl = { cert = "/var/lib/acme/benary.org/cert.pem"; key = "/var/lib/acme/benary.org/key.pem"; };
                    };
                  };
                  uploadHttp =
                  {
                    domain = "xmpp.lxd.bsocat.net";
                    uploadFileSizeLimit = "1024 * 1024 * 512";
                    uploadExpireAfter = "60 * 60 * 24 * 7 * 4";
                    httpUploadPath = "/var/lib/prosody/http_upload";
                  };
                  muc =
                  [
                    {
                      domain = "conference.benary.org";
                      restrictRoomCreation = "local";
                    }
                  ];
                  modules =
                  {
                    admin_adhoc = false;
                    http_files = false;
                    dialback = false;
                  };
                  extraModules = [ "turn_external" "external_services" "http_openmetrics" ];
                  disco_items = [ { url = "xmpp.lxd.bsocat.net"; description = "http upload service"; } ];
                };
                stunnel =
                {
                  enable = true;
                  servers.prometheusMock-prosody =
                  {
                    accept = ":::15280";
                    connect = 5280;
                    cert = "/run/credentials/stunnel.service/cert.pem";
                    key = "/run/credentials/stunnel.service/key.pem";

                    CAFile = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

                    checkHost =
                      let
                        tags = config.benaryorg.prometheus.client.tags;
                        clients = lib.pipe nodes
                        [
                          # get all the node configs
                          builtins.attrValues
                          # filter by those which have the prometheus server
                          (builtins.filter (n: n.config.benaryorg.prometheus.server.enable))
                          # filter by those which have the local tags
                          (builtins.filter (n: any ((flip elem) tags) n.config.benaryorg.prometheus.server.tags))
                        ];
                      in
                        # use the first server
                        # FIXME: https://github.com/NixOS/nixpkgs/issues/221884
                        (builtins.head clients).config.networking.fqdn;

                    # FIXME: https://github.com/NixOS/nixpkgs/issues/221884
                    #socket = [ "l:TCP_NODELAY=1" "r:TCP_NODELAY=1" ];
                    sslVersion = "TLSv1.3";

                    verifyChain = true;
                  };
                };
              };

              system.stateVersion = "23.05";
            };

        "turn.lxd.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.coturnLegoSecret.file = ./secret/lego/hedns/turn.svc.benary.org.age;
              age.secrets.coturnSecret =
              {
                file = ./secret/service/coturn/turn.lxd.bsocat.net.age;
                owner = config.systemd.services.coturn.serviceConfig.User;
              };
              benaryorg.prometheus.client.enable = true;
              security.acme.certs =
              {
                ${config.networking.fqdn}.listenHTTP = ":80";
                "turn.svc.benary.org" =
                {
                  dnsProvider = "hurricane";
                  credentialsFile = config.age.secrets.coturnLegoSecret.path;
                  reloadServices = [ "coturn.service" ];
                  group = config.systemd.services.coturn.serviceConfig.Group;
                };
              };
              services =
              {
                coturn =
                {
                  enable = true;
                  static-auth-secret-file = config.age.secrets.coturnSecret.path;
                  secure-stun = true;
                  no-cli = true;
                  realm = "turn.svc.benary.org";
                  cert = "/var/lib/acme/turn.svc.benary.org/cert.pem";
                  pkey = "/var/lib/acme/turn.svc.benary.org/key.pem";
                };
              };

              system.stateVersion = "23.05";
            };

        "gaycast.lxd.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              benaryorg.prometheus.client.enable = true;

              services =
              {
                owncast.enable = true;
                nginx =
                {
                  enable = true;
                  recommendedProxySettings = true;
                  recommendedTlsSettings = true;
                  virtualHosts =
                  {
                    ${config.networking.fqdn} =
                    {
                      enableACME = true;
                      forceSSL = true;
                      locations."/" =
                      {
                        proxyPass = "http://localhost:${toString config.services.owncast.port}";
                        proxyWebsockets = true;
                      };
                    };
                  };
                };
              };

              system.stateVersion = "23.05";
            };

        "benaryorg1.lxd.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.benaryorgLegoSecret.file = ./secret/lego/hedns/benary.org.age;
              benaryorg.prometheus.client.enable = true;
              benaryorg.website.enable = true;
              services.nginx.virtualHosts.${config.networking.fqdn} =
              {
                enableACME = true;
                forceSSL = true;
                locations."/" = { return = "200 \"Meow.\""; extraConfig = "more_set_headers 'content-type: text/plain';"; };
              };
              security.acme.certs."benary.org" =
              {
                dnsProvider = "hurricane";
                credentialsFile = config.age.secrets.benaryorgLegoSecret.path;
                reloadServices = [ "nginx.service" ];
                group = config.services.nginx.group;
              };

              system.stateVersion = "23.05";
            };

        "benaryorg2.lxd.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.benaryorgLegoSecret.file = ./secret/lego/hedns/benary.org.age;
              benaryorg.prometheus.client.enable = true;
              benaryorg.website.enable = true;
              services.nginx.virtualHosts.${config.networking.fqdn} =
              {
                enableACME = true;
                forceSSL = true;
                locations."/" = { return = "200 \"Meow.\""; extraConfig = "more_set_headers 'content-type: text/plain';"; };
              };
              security.acme.certs."benary.org" =
              {
                dnsProvider = "hurricane";
                credentialsFile = config.age.secrets.benaryorgLegoSecret.path;
                reloadServices = [ "nginx.service" ];
                group = config.services.nginx.group;
              };

              system.stateVersion = "23.05";
            };

        "benaryorg3.lxd.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.benaryorgLegoSecret.file = ./secret/lego/hedns/benary.org.age;
              benaryorg.prometheus.client.enable = true;
              benaryorg.website.enable = true;
              services.nginx.virtualHosts.${config.networking.fqdn} =
              {
                enableACME = true;
                forceSSL = true;
                locations."/" = { return = "200 \"Meow.\""; extraConfig = "more_set_headers 'content-type: text/plain';"; };
              };
              security.acme.certs."benary.org" =
              {
                dnsProvider = "hurricane";
                credentialsFile = config.age.secrets.benaryorgLegoSecret.path;
                reloadServices = [ "nginx.service" ];
                group = config.services.nginx.group;
              };

              system.stateVersion = "23.05";
            };

        "git.shell.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              benaryorg.prometheus.client.enable = true;

              benaryorg.git.adminkey = conf.sshkey."benaryorg@gnutoo.home.bsocat.net";
              benaryorg.git.enable = true;
              benaryorg.git.mirror =
              {
                nixpkgs = { url = "https://github.com/NixOS/nixpkgs.git"; };
                crane = { url = "https://github.com/ipetkov/crane.git"; };
                flake-compat = { url = "https://github.com/edolstra/flake-compat.git"; };
                nix-systems = { url = "https://github.com/nix-systems/default.git"; };
                flake-utils = { url = "https://github.com/numtide/flake-utils.git"; };
                rust-overlay = { url = "https://github.com/oxalica/rust-overlay.git"; };
                agenix = { url = "https://github.com/ryantm/agenix.git"; };
                ragenix = { url = "https://github.com/yaxitech/ragenix.git"; };
                colmena = { url = "https://github.com/zhaofengli/colmena.git"; };
                home-manager = { url = "https://github.com/nix-community/home-manager.git"; };
                nix-darwin = { url = "https://github.com/lnl7/nix-darwin.git"; };
                nix-generators = { url = "https://github.com/nix-community/nixos-generators.git"; };
                nixlib = { url = "https://github.com/nix-community/nixpkgs.lib.git"; };
              };

              system.stateVersion = "23.05";
            };

        "nixos-builder.shell.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              age.secrets.buildSecret.file = ./secret/build/nixos-builder.shell.bsocat.net.age;

              benaryorg.prometheus.client.enable = true;

              benaryorg.build =
              {
                role = "server";
                tags = [ "shell.bsocat.net" "cloud.bsocat.net" "lxd.bsocat.net" ];
                publicKey = "nixos-builder.cloud.bsocat.net:i0hLFuNDkp781rdD1nmikT7vsf90Nluo13AL1QE6TSc=";
                privateKeyFile = config.age.secrets.buildSecret.path;
              };

              nix.settings.allowed-uris = [ "https://git.shell.bsocat.net/" ];
              services.hydra =
              {
                enable = true;
                hydraURL = "https://${config.networking.fqdn}/hydra";
                useSubstitutes = true;
                notificationSender = "hydra@benary.org";
              };
              services.nginx.virtualHosts.${config.networking.fqdn}.locations."/hydra" =
              {
                proxyPass = "http://127.0.0.1:3000/";
                extraConfig =
                ''
                  proxy_set_header x-request-base /hydra;
                '';
              };
              systemd.slices.build =
              {
                enable = true;
                description = "Slice for all services doing build jobs or similar.";
                sliceConfig.MemoryHigh = "24G";
                sliceConfig.MemoryMax = "25G";
              };
              systemd.services =
              {
                nix-daemon = { serviceConfig.Slice = "build.slice"; };
                hydra-evaluator = { serviceConfig.Slice = "build.slice"; };
                hydra-queue-runner = { serviceConfig.Slice = "build.slice"; };
              };

              system.stateVersion = "23.05";
            };

        "mir.home.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              benaryorg.deployment.fake = true;

              benaryorg.build.role = "none";
              benaryorg.prometheus.client.enable = true;
              benaryorg.prometheus.client.exporters.smokeping.enable = false;
              benaryorg.prometheus.client.exporters.systemd.enable = false;
              benaryorg.prometheus.client.mocks.ceph =
              {
                port = 19283;
              };
            };

        "gnutoo.home.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              benaryorg.deployment.fake = true;

              benaryorg.build.role = "none";
              benaryorg.prometheus.client.enable = true;
              benaryorg.prometheus.client.exporters.smokeping.enable = false;
              benaryorg.prometheus.client.exporters.systemd.enable = false;
            };

        "bgp.cloud.bsocat.net" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              benaryorg.deployment.fake = true;

              benaryorg.build.role = "none";
              benaryorg.prometheus.client.enable = true;
              benaryorg.prometheus.client.exporters.node.enable = true;
              benaryorg.prometheus.client.exporters.smokeping.enable = false;
              benaryorg.prometheus.client.exporters.systemd.enable = false;
              benaryorg.prometheus.client.mocks.bgplgd =
              {
                port = 443;
              };
            };

        "kexec.example.com" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              benaryorg.deployment.fake = true;

              imports =
              [
                (nixpkgs + "/nixos/modules/installer/netboot/netboot.nix")
              ];

              benaryorg.base.lightweight = true;
              benaryorg.net.type = "none";
              benaryorg.hardware.vendor = "none";
              benaryorg.flake.enable = false;
              benaryorg.build.role = "client-light";
              benaryorg.build.tags = [ "cloud.bsocat.net" ];
              benaryorg.user.ssh.keys = [ conf.sshkey."benaryorg@shell.cloud.bsocat.net" conf.sshkey."benaryorg@gnutoo.home.bsocat.net" ];
              users.users.root.openssh.authorizedKeys.keys = [ conf.sshkey."benaryorg@shell.cloud.bsocat.net" conf.sshkey."benaryorg@gnutoo.home.bsocat.net" ];
              systemd.services."serial-getty@ttyS0" =
              {
                enable = true;
                wantedBy = [ "getty.target" ];
              };
              services =
              {
                getty.autologinUser = "root";
                lldpd.enable = true;
                unbound.enable = true;
                openssh = lib.mkForce
                {
                  enable = true;
                  settings =
                  {
                    PermitRootLogin = "yes";
                    PasswordAuthentication = false;
                  };
                };
              };
              networking =
              {
                firewall.enable = false;
                wireguard.enable = false;
                tempAddresses = "disabled";
                useDHCP = true;
              };
            };
  
        "iso.example.com" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              benaryorg.deployment.fake = true;

              imports =
              [
                (nixpkgs + "/nixos/modules/installer/cd-dvd/iso-image.nix")
              ];

              benaryorg.base.lightweight = true;
              benaryorg.net.type = "none";
              benaryorg.hardware.vendor = "none";
              benaryorg.flake.enable = false;
              benaryorg.build.role = "client-light";
              benaryorg.build.tags = [ "cloud.bsocat.net" ];
              benaryorg.user.ssh.keys = [ conf.sshkey."benaryorg@shell.cloud.bsocat.net" conf.sshkey."benaryorg@gnutoo.home.bsocat.net" ];
              users.users.root.openssh.authorizedKeys.keys = [ conf.sshkey."benaryorg@shell.cloud.bsocat.net" conf.sshkey."benaryorg@gnutoo.home.bsocat.net" ];
              isoImage =
              {
                isoBaseName = "katze";
                makeBiosBootable = true;
                makeEfiBootable = true;
                makeUsbBootable = true;
              };
              systemd.services."serial-getty@ttyS0" =
              {
                enable = true;
                wantedBy = [ "getty.target" ];
              };
              services =
              {
                getty.autologinUser = "root";
                lldpd.enable = true;
                unbound.enable = true;
                openssh = lib.mkForce
                {
                  enable = true;
                  settings =
                  {
                    PermitRootLogin = "yes";
                    PasswordAuthentication = false;
                  };
                };
              };
              networking =
              {
                firewall.enable = false;
                wireguard.enable = false;
                tempAddresses = "disabled";
                useDHCP = true;
              };
            };

        "lxc.example.com" = { name, nodes, pkgs, lib, config, ... }:
          let
            conf = pkgs.callPackage ./conf {};
          in
            with lib;
            {
              benaryorg.deployment.default = false;
              benaryorg.build.role = "client-light";
              benaryorg.build.tags = [ "cloud.bsocat.net" ];
              benaryorg.flake.autoupgrade = false;

              system.stateVersion = "23.05";
            };
      };
      # build the hive
      colmenaHive = colmena.lib.makeHive colmenaConfig;
      # remove fake hosts
      hosts = builtins.filter (name: !colmenaHive.nodes.${name}.config.benaryorg.deployment.fake) (builtins.attrNames colmenaHive.nodes);
      # create a nixosConfiguration entry
      buildNixosKv = name:
      {
        name = colmenaHive.nodes.${name}.config.networking.hostName;
        value = colmenaHive.nodes.${name};
      };
      # merge the nixosConfiguration entries
      nixosConfig = builtins.listToAttrs (builtins.map buildNixosKv hosts);
      # create a node Hydra job
      buildHydraNodeJobKv = name:
      {
        name = let
            hostname = colmenaHive.nodes.${name}.config.networking.hostName;
          in
            "node-${hostname}";
        value = colmenaHive.nodes.${name}.config.system.build.toplevel
          //
            {
              meta.description = "hydra build for colmena node ${name}";
            };
      };
      # hydra node jobs
      hydraNodeJobs = builtins.listToAttrs (builtins.map buildHydraNodeJobKv hosts);
      # hydra extra jobs
      hydraExtraJobs =
      {
        kexec = colmenaHive.nodes."kexec.example.com".config.system.build.kexecTree;
        iso = colmenaHive.nodes."iso.example.com".config.system.build.isoImage;
      };
      addHydraMeta = name: { meta ? {}, ... }@value: value //
      {
        meta =
          let
            metaDefault = name: default: if builtins.hasAttr name meta then builtins.getAttr name meta else default;
            metaMerge = attrs: meta // (builtins.mapAttrs metaDefault attrs);
          in
            metaMerge
            {
              description = "hydra job ${name}";
              license = [ { shortName = "AGPL-3.0-or-later"; } ];
              homepage = "https://git.shell.bsocat.net/infra/";
              maintainers = [ { email = "root@benary.org"; } ];
              schedulingPriority = 10;
              timeout = 36000;
              maxSilent = 7200;
            };
      };
      nixosModules = rec
      {
        benaryorg =
        {
          imports =
          [
            ragenix.nixosModules.default
            benaryorg-website.nixosModules.default
            lxddns.nixosModules.default
            ./spec/base.nix
            ./spec/deployment.nix
            ./spec/user.nix
            ./spec/ssh.nix
            ./spec/nix.nix
            ./spec/flake.nix
            ./spec/nullmailer.nix
            ./spec/hardware.nix
            ./spec/git.nix
            ./spec/net.nix
            ./spec/prometheus.nix
            ./spec/lxd.nix
            ./spec/build.nix
          ];

          config =
            let
              conf = pkgs.callPackage ./conf {};
            in
              {
                nixpkgs.overlays = [ benaryorg-website.overlays.default ragenix.overlays.default lxddns.overlays.default ];
                benaryorg.user.ssh.keys = [ conf.sshkey."benaryorg@shell.cloud.bsocat.net" ];
              };
        };
        default = benaryorg;
      };
    in
      {
        colmena = colmenaConfig;
        nixosConfigurations = nixosConfig;
        nixosModules = nixosModules;
        hydraJobs = builtins.mapAttrs addHydraMeta (hydraNodeJobs // hydraExtraJobs);
      };
}
