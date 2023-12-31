{ nixpkgs, nodes, config, pkgs, lib, options, ... }:
with lib;
{
  options =
  {
    benaryorg.build =
    {
      role = mkOption
      {
        type = types.enum [ "client" "client-light" "server" "none" ];
        description = mdDoc
        ''
          In what role to act.
          A `server` provides build services as well as a binary cache via SSH and HTTPS including appropriate signatures.
          A `client` will consume the build services and binary cache.
          A `client-light` will only consume the binary cache.
          `none` opts out of the entire module.
        '';
        default = "client";
      };
      tags = mkOption
      {
        type = types.listOf types.str;
        default = [ config.networking.domain ];
        description = mdDoc
        ''
          List of tags to use/serve.

          Tags can be added to clients and servers, servers will be usable by all clients containing any of the specified tags.
          This allows for an n:m relation between clients and servers.
          The default is the netwoking domain.
        '';
      };
      publicKey = mkOption
      {
        type = types.nullOr types.str;
        default = null;
        description = "Only required for servers, denotes the public key used for signing.";
      };
      privateKeyFile = mkOption
      {
        type = types.nullOr types.str;
        default = null;
        description = "Only required for servers, denotes the private key file used for signing (provide via secret).";
      };
      features = mkOption
      {
        type = types.listOf types.str;
        default = [ "big-parallel" ];
        description = "Only required for servers, denotes the supported features.";
      };
      system = mkOption
      {
        type = types.str;
        default = "x86_64-linux";
        description = "Only required for servers, denotes the supported arch.";
      };
      doc = mkOption
      {
        type = types.bool;
        default = true;
        description = "Only relevant for servers, exposes nixos documentation on /doc via HTTPS.";
      };
    };
  };

  config =
    let
      cfg = config.benaryorg.build;
      globalConf = pkgs.callPackage ../conf {};
      hostkey = globalConf.hostkey;
    in
      mkMerge
      [
        (mkIf (cfg.role == "server")
        {
          nix.settings.trusted-users = [ "nix-ssh" ];
          nix.settings.secret-key-files = [ cfg.privateKeyFile ];
          nix.sshServe =
          {
            enable = true;
            write = true;
            protocol = "ssh-ng";
            keys = lib.pipe nodes
            [
              # get all the node configs
              builtins.attrValues
              # filter by those which are clients
              (builtins.filter (n: n.config.benaryorg.build.role == "client"))
              # filter by those which have the local tags
              (builtins.filter (n: any ((flip elem) cfg.tags) n.config.benaryorg.build.tags))
              # map to hostkeys
              (builtins.map (node: hostkey.${node.config.networking.fqdn}))
            ];
          };
          services =
          {
            nix-serve =
            {
              enable = true;
              secretKeyFile = cfg.privateKeyFile;
              bindAddress = "127.0.0.1";
              port = 5000;
            };
            nginx =
            {
              enable = true;
              recommendedProxySettings = true;
              recommendedTlsSettings = true;
              virtualHosts =
              {
                ${config.networking.fqdn} =
                {
                  forceSSL = true;
                  enableACME = true;
                  locations =
                  {
                    "/" =
                    {
                      proxyPass = "http://127.0.0.1:5000";
                    };
                    "/doc/" = mkIf config.benaryorg.build.doc
                    {
                      alias = "${config.system.build.manual.manualHTML}/share/doc/nixos/";
                    };
                  };
                };
              };
            };
          };
        })
        (
          let
            server = lib.pipe nodes
            [
              # get all the node configs
              builtins.attrValues
              # filter by those which are servers
              (builtins.filter (n: n.config.benaryorg.build.role == "server"))
              # filter by those which have the local tags
              (builtins.filter (n: any ((flip elem) cfg.tags) n.config.benaryorg.build.tags))
            ];
          in
            mkIf (cfg.role == "client" || cfg.role == "client-light")
            {
              nix.distributedBuilds = cfg.role == "client";
              nix.settings.trusted-public-keys = map (node: node.config.benaryorg.build.publicKey) server;
              nix.settings.substituters = map (node: "https://${node.config.networking.fqdn}") server;
              nix.buildMachines = mkIf (cfg.role == "client") (lib.pipe server
              [
                # map to entry (hostkeys are global in base)
                (builtins.map (node:
                {
                  hostName = node.config.networking.fqdn;
                  protocol = "ssh-ng";
                  sshKey = "/etc/ssh/ssh_host_ed25519_key";
                  sshUser = "nix-ssh";
                  supportedFeatures = node.config.benaryorg.build.features;
                  system = node.config.benaryorg.build.system;
                }))
              ]);
            })
      ];
}
