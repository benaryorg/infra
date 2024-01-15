{ nixpkgs, nodes, config, pkgs, lib, options, ... }:
{
  options =
  {
    benaryorg.prometheus =
    {
      useAcme = lib.mkOption
      {
        type = lib.types.bool;
        default = config.benaryorg.prometheus.server.enable || config.benaryorg.prometheus.client.enable;
        description = "Whether to pull ACME certificates.";
      };
      server =
      {
        enable = lib.mkOption
        {
          type = lib.types.bool;
          default = false;
          description = "Whether to enable the prometheus server.";
        };
        tags = lib.mkOption
        {
          type = lib.types.listOf lib.types.str;
          default = [ "default" ];
          description = lib.mdDoc
          ''
            List of tags to monitor with this server.

            Tags can be added to clients and servers, servers will scrape all clients containing any of the specified tags.
            This allows for several servers to scrape different sets of clients.
          '';
        };
      };
      client =
      {
        enable = lib.mkOption
        {
          type = lib.types.bool;
          default = false;
          description = "Whether to enable the prometheus client.";
        };
        tags = lib.mkOption
        {
          type = lib.types.listOf lib.types.str;
          default = [ "default" ];
          description = lib.mdDoc
          ''
            List of tags to monitor with this server.

            Tags can be added to clients and servers, servers will scrape all clients containing any of the specified tags.
            This allows for several servers to scrape different sets of clients.
          '';
        };
        exporters = lib.mkOption
        {
          default = {};
          description = lib.mdDoc
          ''
            Set of paramaters to be passed to {option}`services.prometheus.exporters`.
            All `listenAddress` parameters will default to `[::1]`.
            Ports will remain unchanged, however each exporter will be deployed with a corresponding *stunnel* instance.
            The stunnel instance will listen publicly on the same port shifted upwards by 10000 and provide mTLS authentication based on public certificates and SAN verification.
            The allowed SANs per exporter will be derived via the {option}`benaryorg.prometheus.client.tags` option.
          '';
        };
        mocks = lib.mkOption
        {
          default = {};
          description = lib.mdDoc
          ''
            Use this to add a prometheus exporter for this client in cases where the exporter is not managed by {option}`services.prometheus.exporters`.
            This can be used to add arbitrary HTTP endpoints such as those offered by `prosody` or `kubo` to the scraped exporters with minimal overhead.
          '';
          type = lib.types.attrsOf (lib.types.submodule
          {
            options =
            {
              enable = lib.mkOption
              {
                type = lib.types.bool;
                default = true;
                description = "Whether to enable the mock.";
              };
              port = lib.mkOption
              {
                type = lib.types.port;
                description = lib.mdDoc
                ''
                  Which port to scrape.
                  Unless changed by the `scrapeConfig` override, this expects a TLS capable endpoint running on the FQDN of the configured host.
                  The endpoint must provide valid certificates for the FQDN and should verify the certificates presented by the prometheus scraper, corresponding to the FQDN (or FQDNs) of the matching hosts as per {option}`benaryorg.prometheus.client.tags`.
                  These options have no effect on the client and will only be used on the server to construct the scrape configuration.
                '';
              };
              scrapeConfig = lib.mkOption
              {
                default = {};
                description = lib.mdDoc
                ''
                  Scrape configuration as used in prometheus, used to provide values diverging from the defaults.
                  This can be used to scrape using other protocols than HTTPS for instance.
                '';
              };
            };
          });
        };
      };
    };
  };

  config = lib.mkMerge
    [
      (lib.mkIf config.benaryorg.prometheus.server.enable
      {
        services.prometheus =
        {
          enable = true;
          enableReload = false;
          checkConfig = "syntax-only";
          listenAddress = "[::1]";
          scrapeConfigs =
            let
              tags = config.benaryorg.prometheus.server.tags;
              clients = lib.pipe nodes
              [
                # get all the node configs
                builtins.attrValues
                # filter by those which have the prometheus client
                (builtins.filter (n: n.config.benaryorg.prometheus.client.enable))
                # filter by those which have the local tags
                (builtins.filter (n: lib.any ((lib.flip builtins.elem) tags) n.config.benaryorg.prometheus.client.tags))
                # simplify the node attrset
                (builtins.map
                  (node:
                    {
                      fqdn = node.config.networking.fqdn;
                      # filter for attrs, there seem to be "warnings" and "assertions" present as lists
                      exporters = lib.filterAttrs (name: value: (builtins.isAttrs value) && value.enable) node.config.services.prometheus.exporters;
                      mocks = lib.filterAttrs (name: value: (builtins.isAttrs value) && value.enable) node.config.benaryorg.prometheus.client.mocks;
                    }
                  )
                )
              ];
              # get all exporters active on possible clients
              exporterList = lib.unique (builtins.concatMap (n: builtins.attrNames n.exporters) clients);
              # generate one job per exporter
              job = exporter: clients: lib.pipe clients
              [
                (builtins.filter (n: builtins.elem exporter (builtins.attrNames n.exporters)))
                (clients:
                  {
                    job_name = exporter;
                    static_configs =
                    [
                      {
                        targets = builtins.map (node: "${node.fqdn}:${toString (node.exporters.${exporter}.port + 10000)}") clients;
                      }
                    ];
                    scheme = "https";
                    tls_config =
                    {
                      ca_file = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
                      cert_file = "/run/credentials/prometheus.service/cert.pem";
                      key_file = "/run/credentials/prometheus.service/key.pem";
                    };
                  }
                )
              ];
              # build scrape configuration from single mock
              mockToScrapeConfig = { name, mock, fqdn }:
                lib.mergeAttrs
                  {
                    job_name = "${name}:${fqdn}";
                    static_configs =
                    [
                      {
                        targets = [ "${fqdn}:${toString mock.port}" ];
                      }
                    ];
                    scheme = "https";
                    tls_config =
                    {
                      ca_file = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
                      cert_file = "/run/credentials/prometheus.service/cert.pem";
                      key_file = "/run/credentials/prometheus.service/key.pem";
                    };
                  }
                  mock.scrapeConfig;
              # get a list of mocks for each client
              clientToMocks = client: lib.pipe client.mocks
              [
                (builtins.mapAttrs (name: value: { fqdn = client.fqdn; name = name; mock = value; }))
                builtins.attrValues
                (builtins.filter (mock: mock.mock.enable))
              ];
              # get additional scrape configuration for list of clients
              extraScrapeConfigs = clients: lib.pipe clients [ (builtins.concatMap clientToMocks) (builtins.map mockToScrapeConfig) ];
            in
              (builtins.map (exporter: job exporter clients) exporterList) ++ (extraScrapeConfigs clients);
        };
        systemd.services.prometheus =
        {
          wants = [ "acme-finished-${config.networking.fqdn}.target" ];
          after = [ "acme-finished-${config.networking.fqdn}.target" ];
          serviceConfig.LoadCredential =
          [
            "cert.pem:/var/lib/acme/${config.networking.fqdn}/cert.pem"
            "key.pem:/var/lib/acme/${config.networking.fqdn}/key.pem"
          ];
        };
      })
      (lib.mkIf config.benaryorg.prometheus.client.enable
      {
        benaryorg.prometheus.client.exporters.node.enable = true;
        benaryorg.prometheus.client.exporters.smokeping.enable = true;
        benaryorg.prometheus.client.exporters.systemd.enable = true;
        services.prometheus.exporters =
          let
            exporterDefaultFunction = key: value:
            {
              listenAddress = "[::1]";
            };
            exporterDefaults =
            {
              node.enabledCollectors =
              [
                "cgroups"
                "cpu.guest"
                "cpu.info"
                "drm"
                "ethtool"
                "netdev.address-info"
                "network_route"
                "os"
                "slabinfo"
                "systemd"
                "zoneinfo"
              ];
              smokeping =
              {
                buckets = "5e-05,0.001,0.002,0.005,0.01,0.015,0.02,0.025,0.03,0.04,0.05,0.075,0.1,0.15,0.2,0.25,0.3,0.4,0.5,0.75,0.9,1,1.2,1.6,2,5,10";
                hosts =
                [
                  "ipv4.syseleven.de"
                  "ipv6.syseleven.de"
                ];
              };
              unbound =
              {
                controlInterface = "/run/unbound/unbound.socket";
                group = config.services.unbound.group;
              };
            };
            exporters = builtins.mapAttrs (key: value: (exporterDefaultFunction key value) // (lib.attrByPath [ key ] {} exporterDefaults) // value) config.benaryorg.prometheus.client.exporters;
          in
            exporters;

        systemd.services =
        {
          stunnel =
          {
            wants = [ "acme-finished-${config.networking.fqdn}.target" ];
            after = [ "acme-finished-${config.networking.fqdn}.target" ];
            serviceConfig.LoadCredential =
            [
              "cert.pem:/var/lib/acme/${config.networking.fqdn}/cert.pem"
              "key.pem:/var/lib/acme/${config.networking.fqdn}/key.pem"
            ];
          };
          # if systemd resolved restarts then this service restarts too
          # it may take a little for dns resolution to work again
          # and the service fails early if DNS cannot be resolved
          prometheus-smokeping-exporter.serviceConfig =
          {
            RestartSec = "1min";
            TimeoutStartSec = "5min";
            RestartMode = "direct";
          };
        };

        services.stunnel =
        {
          enable = true;
          servers =
            let
              exporterList = builtins.attrNames config.benaryorg.prometheus.client.exporters;
              stunnelServer = name: exporterConfig:
              {
                accept = ":::${toString (exporterConfig.port + 10000)}";
                connect = exporterConfig.port;
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
                      (builtins.filter (n: lib.any ((lib.flip builtins.elem) tags) n.config.benaryorg.prometheus.server.tags))
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
              mapExporterFunction = name:
              {
                name = "prometheusExporter-${name}";
                value = stunnelServer name config.services.prometheus.exporters.${name};
              };
              servers = lib.pipe exporterList [ (builtins.map mapExporterFunction) builtins.listToAttrs ];
            in
              servers;
        };
      })
      (lib.mkIf config.benaryorg.prometheus.useAcme
      {
        security.acme.certs.${config.networking.fqdn} =
        {
          reloadServices = (lib.optional config.benaryorg.prometheus.server.enable "prometheus.service") ++ (lib.optional config.benaryorg.prometheus.client.enable "stunnel.service");
        };
      })
    ];
}
