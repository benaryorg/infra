{ nodes, config, pkgs, lib, options, ... }:
{
  options =
  {
    benaryorg.lxd =
    {
      enable = lib.mkEnableOption (lib.mdDoc "the opinionated LXD cluster configuration.");
      cluster = lib.mkOption
      {
        description = "Name of the LXD cluster to integrate with.";
        type = lib.types.str;
      };
      legoConfig = lib.mkOption
      {
        description = "Lego certificate configuration.";
      };
      network = lib.mkOption
      {
        default = lib.pipe config.benaryorg.net.host.ipv6
        [
          (lib.splitString "/")
          builtins.head
          (lib.splitString ":")
          (lib.take 4)
          (lib.concatStringsSep ":")
        ];
        example = "2001:db8:1234:cdef";
        description = "IPv6 /64 to use; only the first four hextets.";
        type = lib.types.str;
      };
      extInterface = lib.mkOption
      {
        default = config.benaryorg.net.host.primaryInterface;
        description = "External interface.";
        type = lib.types.str;
      };
      bridge = lib.mkOption
      {
        default = "br0";
        description = "Internal IPv6 only bridge.";
        type = lib.types.str;
      };
      extraRemotes = lib.mkOption
      {
        default = [];
        description = "Additional lxddns remotes.";
        type = lib.types.listOf lib.types.str;
      };
      hostmaster = lib.mkOption
      {
        default = "hostmaster.benary.org";
        description = "Hostmaster address in DNS notation (for SOA).";
        type = lib.types.str;
      };
      lxddnsPort = lib.mkOption
      {
        default = 9132;
        description = "Port to bind lxddns to.";
        type = lib.types.int;
      };
      lxddnsAddress = lib.mkOption
      {
        default = "[::]";
        description = "Address to bind lxddns to.";
        type = lib.types.str;
      };
      legacySmtpProxy = lib.mkOption
      {
        default = false;
        description = "Whether to enable a legacy setup-specific SMTP proxy.";
        type = lib.types.bool;
      };
      allowedUsers = lib.mkOption
      {
        default = if config.benaryorg.user.ssh.enable then [ config.benaryorg.user.ssh.name ] else [];
        description = "List of users which are allowed to access the LXD server.";
        type = lib.types.listOf lib.types.str;
      };
    };
  };

  config = lib.mkIf config.benaryorg.lxd.enable
  {
    benaryorg.deployment.tags = lib.mkAfter [ "lxd" "lxd:${config.benaryorg.lxd.cluster}" ];
    virtualisation.lxd =
    {
      enable = true;
      recommendedSysctlSettings = true;
    };
    security.acme.certs.${config.networking.fqdn} =
    {
      reloadServices = [ "lxddns-responder.service" ];
    } // config.benaryorg.lxd.legoConfig;

    users.groups.lxd.members = config.benaryorg.lxd.allowedUsers;

    # lxd user/group for extra large uid ranges
    users.users.root =
    {
      subUidRanges = lib.mkForce [ { startUid = 1000000000; count = 1000000000; } ];
      subGidRanges = lib.mkForce [ { startGid = 1000000000; count = 1000000000; } ];
    };

    boot.kernel.sysctl =
    {
      "net.ipv4.ip_forward" = true;
    };
    services.ndppd =
    {
      enable = true;
      proxies =
      {
        ${config.benaryorg.lxd.extInterface} =
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
        wants = [ "acme-finished-${config.networking.fqdn}.target" ];
        after = [ "acme-finished-${config.networking.fqdn}.target" ];
      };
      pdns =
      {
        wants = [ "lxddns-responder.service" ];
        after = [ "lxddns-responder.service" ];
      };
      nginx =
      {
        wants = [ "pdns.service" ];
        after = [ "pdns.service" ];
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
      lxddns-responder =
      {
        enable = true;
        http =
        {
          listenAddress = config.benaryorg.lxd.lxddnsAddress;
          listenPort = config.benaryorg.lxd.lxddnsPort;
        };
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
            clusterNodes = builtins.filter (x: x.config.benaryorg.lxd.enable && x.config.benaryorg.lxd.cluster == config.benaryorg.lxd.cluster) (builtins.attrValues nodes);
            managedRemotes = builtins.map (x: "https://${x.config.networking.fqdn}:${toString x.config.benaryorg.lxd.lxddnsPort}") clusterNodes;
            remotes = lib.concatMapStringsSep " " (x: "--remote ${x}") (config.benaryorg.lxd.extraRemotes ++ managedRemotes);
          in
            ''
              api=no
              remote-connection-string=pipe:command=${pkgs.lxddns-http}/bin/lxddns-http pipe -v info --domain ${config.benaryorg.lxd.cluster}. --hostmaster ${config.benaryorg.lxd.hostmaster} ${remotes} --soa-ttl 64 --aaaa-ttl 256,timeout=5000
              launch=remote
              negquery-cache-ttl=1
              local-address=${builtins.head (lib.splitString "/" config.benaryorg.net.host.ipv6)}, ${builtins.head (lib.splitString "/" config.benaryorg.net.host.ipv4)}
              # needed since 4.5
              zone-cache-refresh-interval=0
            '';
      };
      # FIXME: this is probably not going away anytime soon
      # It would be incredibly useful to have this configuration
      # live in the container config and be pulled from there.
      # Of course that requires a rather elaborate way to assign
      # containers to clusters, but that should be doable?
      nginx = lib.mkIf config.benaryorg.lxd.legacySmtpProxy
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
