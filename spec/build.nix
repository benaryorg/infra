{ nixpkgs, nodes, config, pkgs, lib, options, ... }:
{
  options =
  {
    benaryorg.build =
    {
      role = lib.mkOption
      {
        type = lib.types.enum [ "client" "client-light" "server" "none" ];
        description = lib.mdDoc
        ''
          In what role to act.
          A `server` provides build services as well as a binary cache via SSH and HTTPS including appropriate signatures.
          A `client` will consume the build services and binary cache.
          A `client-light` will only consume the binary cache.
          `none` opts out of the entire module.
        '';
        default = "client";
      };
      tags = lib.mkOption
      {
        type = lib.types.listOf lib.types.str;
        default = [ config.networking.domain ];
        defaultText = lib.literalExpression "[ config.networking.domain ]";
        description = lib.mdDoc
        ''
          List of tags to use/serve.

          Tags can be added to clients and servers, servers will be usable by all clients containing any of the specified tags.
          This allows for an n:m relation between clients and servers.
          The default is the netwoking domain.
        '';
      };
      publicKey = lib.mkOption
      {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Only required for servers, denotes the public key used for signing.";
      };
      privateKeyFile = lib.mkOption
      {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Only required for servers, denotes the private key file used for signing (provide via secret).";
      };
      features = lib.mkOption
      {
        type = lib.types.listOf lib.types.str;
        default = [ "big-parallel" ];
        description = "Only required for servers, denotes the supported features.";
      };
      system = lib.mkOption
      {
        type = lib.types.str;
        default = "x86_64-linux";
        description = "Only required for servers, denotes the supported arch.";
      };
      doc = lib.mkOption
      {
        type = lib.types.bool;
        default = true;
        description = lib.mdDoc "Only relevant for servers, exposes nixos documentation on `/doc` via HTTPS.";
      };
    };
  };

  config =
    let
      cfg = config.benaryorg.build;
    in
      lib.mkMerge
      [
        (lib.mkIf (cfg.role == "server")
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
              (builtins.filter (n: lib.any ((lib.flip builtins.elem) cfg.tags) n.config.benaryorg.build.tags))
              # map to hostkeys
              (builtins.map (n: n.config.benaryorg.ssh.hostkey))
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
                    "/doc/" = lib.mkIf config.benaryorg.build.doc
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
              (builtins.filter (n: lib.any ((lib.flip builtins.elem) cfg.tags) n.config.benaryorg.build.tags))
            ];
          in
            lib.mkIf (cfg.role == "client" || cfg.role == "client-light")
            {
              nix.distributedBuilds = cfg.role == "client";
              nix.settings.trusted-public-keys = builtins.map (node: node.config.benaryorg.build.publicKey) server;
              nix.settings.substituters = builtins.map (node: "https://${node.config.networking.fqdn}") server;
              nix.buildMachines = lib.mkIf (cfg.role == "client") (lib.pipe server
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
