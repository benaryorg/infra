{ nodes, config, pkgs, lib, options, ... }:
with lib;
{
  options =
  {
    benaryorg.lxd =
    {
      enable = mkOption
      {
        default = false;
        description = "Whether to enable the opinionated LXD cluster configuration.";
        type = types.bool;
      };
      cluster = mkOption
      {
        description = "Name of the LXD cluster to integrate with.";
        type = types.str;
      };
      legoConfig = mkOption
      {
        description = "Lego certificate configuration.";
      };
      network = mkOption
      {
        default = pipe config.benaryorg.net.host.ipv6
        [
          (splitString "/")
          builtins.head
          (splitString ":")
          (take 4)
          (concatStringsSep ":")
        ];
        example = "2001:db8:1234:cdef";
        description = "IPv6 /64 to use; only the first four hextets.";
        type = types.str;
      };
      extInterface = mkOption
      {
        default = config.benaryorg.net.host.primaryInterface;
        description = "External interface.";
        type = types.str;
      };
      bridge = mkOption
      {
        default = "br0";
        description = "Internal IPv6 only bridge.";
        type = types.str;
      };
      extraRemotes = mkOption
      {
        default = [];
        description = "Additional lxddns remotes.";
        type = types.listOf types.str;
      };
      hostmaster = mkOption
      {
        default = "hostmaster.benary.org";
        description = "Hostmaster address in DNS notation (for SOA).";
        type = types.str;
      };
      lxddnsPort = mkOption
      {
        default = 9132;
        description = "Port to bind lxddns to.";
        type = types.int;
      };
      lxddnsAddress = mkOption
      {
        default = "[::]";
        description = "Address to bind lxddns to.";
        type = types.str;
      };
    };
  };

  config =
    let
      lxddns = pkgs.callPackage ../pkgs/lxddns {};
    in
      mkIf config.benaryorg.lxd.enable
      {
        virtualisation.lxd =
        {
          enable = true;
          recommendedSysctlSettings = true;
        };
        security.acme.acceptTerms = true;
        security.acme.certs."${config.networking.fqdn}" =
        {
          reloadServices = [ "lxddns-responder.service" ];
          group = "lxddns";
        } // config.benaryorg.lxd.legoConfig;

        users.groups.lxddns = {};
        users.users.lxddns =
        {
          isSystemUser = true;
          group = "lxddns";
        };
        security.sudo =
        {
          enable = true;
          extraConfig =
          ''
            Defaults:lxddns !syslog
          '';
          extraRules = mkOrder 1500
          [
            {
              users = [ "lxddns" ];
              commands =
              [
                { command = "${pkgs.lxd}/bin/lxc query -- *"; options = [ "NOPASSWD" ]; }
              ];
            }
          ];
        };

        systemd.services =
        {
          lxddns-responder =
          {
            enable = true;
            description = "lxddns responder";
            path = [ "/run/wrappers" pkgs.lxd ];
            unitConfig =
            {
              Type = "simple";
            };
            serviceConfig =
            {
              ExecStart = "${lxddns}/bin/lxddns-http responder -v info --tls-chain /var/lib/acme/${config.networking.fqdn}/fullchain.pem --tls-key /var/lib/acme/${config.networking.fqdn}/key.pem --https-bind ${config.benaryorg.lxd.lxddnsAddress}:${toString config.benaryorg.lxd.lxddnsPort}";
              User = "lxddns";
              Group = "lxddns";
            };
            wantedBy = [ "multi-user.target" ];
          };
        };

        networking.bridges."${config.benaryorg.lxd.bridge}".interfaces = [];
        networking.interfaces."${config.benaryorg.lxd.bridge}" =
        {
          ipv6.addresses = [ { address = "${config.benaryorg.lxd.network}::2"; prefixLength = 64; } ];
        };

        services =
        {
          ndppd =
          {
            enable = true;
            proxies =
            {
              "${config.benaryorg.lxd.bridge}".rules."${config.benaryorg.lxd.network}::1/128".method = "static";
              "${config.benaryorg.lxd.extInterface}" =
              {
                router = false;
                rules."${config.benaryorg.lxd.network}::/64" =
                {
                  method = "iface";
                  interface = config.benaryorg.lxd.bridge;
                };
              };
            };
          };
          radvd =
          {
            enable = true;
            config =
            ''
              interface ${config.benaryorg.lxd.bridge}
              {
                AdvSendAdvert on;
                IgnoreIfMissing on;
                MinRtrAdvInterval 3;
                MaxRtrAdvInterval 10;
                AdvDefaultPreference medium;
                AdvHomeAgentFlag off;
                prefix ${config.benaryorg.lxd.network}::/64
                {
                  AdvOnLink on;
                  AdvAutonomous on;
                  AdvRouterAddr on;
                };
                RDNSS ${config.benaryorg.lxd.network}::2
                {
                };
                DNSSL ${config.benaryorg.lxd.cluster}
                {
                };
              };
            '';
          };
          unbound.settings.server =
          {
            interface = [ "::1" "127.0.0.1" "${config.benaryorg.lxd.network}::2" ];
            access-control = [ "::1/128 allow" "127.0.0.0/8 allow" "${config.benaryorg.lxd.network}::/64 allow" ];
          };
          powerdns =
          {
            enable = true;
            extraConfig =
              let
                clusterNodes = builtins.filter (x: x.config.benaryorg.lxd.enable && x.config.benaryorg.lxd.cluster == config.benaryorg.lxd.cluster) (attrValues nodes);
                managedRemotes = builtins.map (x: "https://${x.config.networking.fqdn}:${toString x.config.benaryorg.lxd.lxddnsPort}") clusterNodes;
                remotes = concatMapStringsSep " " (x: "--remote ${x}") (config.benaryorg.lxd.extraRemotes ++ managedRemotes);
              in
                ''
                  api=no
                  remote-connection-string=pipe:command=${lxddns}/bin/lxddns-http pipe -v info --domain ${config.benaryorg.lxd.cluster}. --hostmaster ${config.benaryorg.lxd.hostmaster} ${remotes},timeout=5000
                  launch=remote
                  negquery-cache-ttl=1
                  local-address=${builtins.head (splitString "/" config.benaryorg.net.host.ipv6)}, ${builtins.head (splitString "/" config.benaryorg.net.host.ipv4)}
                  # needed since 4.5
                  zone-cache-refresh-interval=0
                '';
          };
        };
      };
}
