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
        deployment.tags = [ "lxd" "lxd:${config.benaryorg.lxd.cluster}" ];
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

        users.groups.lxd.members = mkIf config.benaryorg.user.ssh.enable [ config.benaryorg.user.ssh.name ];

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

        services.ndppd =
        {
          enable = true;
          proxies =
          {
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

        systemd.network =
        {
          networks =
          {
            "40-external" =
            {
              networkConfig =
              {
                IPForward = true;
                IPv6SendRA = false;
                IPv6AcceptRA = true;
              };
              ipv6RoutePrefixes =
              [
                {
                  ipv6RoutePrefixConfig =
                  {
                      Route = "${config.benaryorg.lxd.network}::/64";
                  };
                }
              ];
              ipv6SendRAConfig =
              {
                RouterPreference = "high";
              };
            };
            "50-internal" =
            {
              enable = true;
              name = "br0";
              addresses = [ { addressConfig = { Address = "${config.benaryorg.lxd.network}::2/64"; }; } ];
              networkConfig =
              {
                IPForward = true;
                IPv6ProxyNDP = true;
                IPv6ProxyNDPAddress = [ "${config.benaryorg.lxd.network}::1" ];
                IPv6SendRA = true;
                IPv6AcceptRA = false;
                ConfigureWithoutCarrier = true;
              };
              ipv6SendRAConfig =
              {
                EmitDNS = true;
                DNS = [ "${config.benaryorg.lxd.network}::2" ];
                EmitDomains = true;
                Domains = [ config.benaryorg.lxd.cluster ];
              };
              ipv6Prefixes =
              [
                {
                  ipv6PrefixConfig =
                  {
                      Prefix = "${config.benaryorg.lxd.network}::/64";
                  };
                }
              ];
              ipv6RoutePrefixes =
              [
                {
                  ipv6RoutePrefixConfig =
                  {
                      Route = "${config.benaryorg.lxd.network}::1/128";
                  };
                }
              ];
              linkConfig =
              {
                RequiredForOnline = false;
              };
            };
          };
          netdevs =
          {
            "50-internal" =
            {
              netdevConfig =
              {
                Name = "br0";
                Kind = "bridge";
              };
            };
          };
        };

        services =
        {
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
          # FIXME: this is probably not going away anytime soon
          # It would be incredibly useful to have this configuration
          # live in the container config and be pulled from there.
          # Of course that requires a rather elaborate way to assign
          # containers to clusters, but that should be doable?
          nginx =
          {
            enable = true;
            streamConfig =
            ''
              upstream smtps {
                server smtp1.lxd.bsocat.net:465;
                server smtp2.lxd.bsocat.net:465;
              }
              server {
                listen     0.0.0.0:465;
                proxy_pass smtps;
              }
              upstream smtp {
                server smtp1.lxd.bsocat.net:25;
                server smtp2.lxd.bsocat.net:25;
              }
              server {
                listen     0.0.0.0:25;
                proxy_pass smtp;
              }
            '';
          };
        };
      };
}
