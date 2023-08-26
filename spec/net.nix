{ config, pkgs, lib, options, ... }:
with lib;
{
  options =
  {
    benaryorg.net =
    {
      type = mkOption
      {
        default = if config.benaryorg.hardware.vendor == "container" then "container" else "host";
        description = "Which type of networking to deploy.";
        type = types.enum [ "container" "host" "manual" "none" ];
      };
      unbound =
      {
        enable = mkOption
        {
          default = config.benaryorg.net.type == "host";
          description = "Whether to enable local unbound.";
          type = types.bool;
        };
      };
      rdnssd =
      {
        enable = mkOption
        {
          default = config.benaryorg.net.type == "container";
          description = "Whether to enable rdnssd.";
          type = types.bool;
        };
      };
      host =
      {
        primaryInterface = mkOption
        {
          description = "The primary network interface.";
          type = types.str;
        };
        ipv4 = mkOption
        {
          description = "IPv4 address in CIDR notation.";
          type = types.nullOr types.str;
        };
        ipv6 = mkOption
        {
          description = "IPv6 address in CIDR notation.";
          type = types.nullOr types.str;
        };
        ipv4Gateway = mkOption
        {
          description = "IPv4 gateway address.";
          type = types.str;
        };
        ipv6Gateway = mkOption
        {
          description = "IPv6 gateway address.";
          type = types.str;
        };
      };
    };
  };

  config = mkIf (config.benaryorg.net.type != "none") (mkMerge
  [
    {
      networking =
      {
        firewall.enable = false;
        wireguard.enable = false;
        tempAddresses = "disabled";
        # this is just the global DHCP option, individual interfaces may still use DHCP
        useDHCP = false;
      };
      services.rdnssd.enable = config.benaryorg.net.rdnssd.enable;
    }
    (mkIf config.benaryorg.net.unbound.enable
    {
      services =
      {
        unbound =
        {
          enable = true;
          localControlSocketPath = "/run/unbound/unbound.socket";
          settings.remote-control.control-enable = true;
        };
        resolved.enable = false;
      };
      benaryorg.prometheus.client.exporters.unbound.enable = true;
    })
    (mkIf (config.benaryorg.net.type == "container")
    {
      services.resolved.enable = false;
      systemd.services.systemd-networkd.serviceConfig.ExecStartPre = [ "-+${pkgs.systemd}/bin/udevadm trigger" ];
      systemd.network =
      {
        enable = true;
        wait-online =
        {
          enable = true;
          ignoredInterfaces = [ "eth1" ];
        };
        networks =
        {
          "40-ipv6" =
          {
            enable = true;
            name = "eth0";
            DHCP = "no";
            ipv6AcceptRAConfig =
            {
              DHCPv6Client = false;
              UseDNS = true;
            };
          };
          "40-ipv4" =
          {
            enable = true;
            name = "eth1";
            DHCP = "ipv4";
            dhcpV4Config =
            {
              UseDNS = false;
            };
          };
        };
      };
    })
    (mkIf (config.benaryorg.net.type == "host")
    {
      systemd.network =
      {
        enable = true;
        networks =
        {
          "40-external" =
          {
            enable = true;
            name = "${config.benaryorg.net.host.primaryInterface}";
            addresses =
            [
              (mkIf (config.benaryorg.net.host.ipv4 != null) { addressConfig = { Address = config.benaryorg.net.host.ipv4; }; })
              (mkIf (config.benaryorg.net.host.ipv6 != null) { addressConfig = { Address = config.benaryorg.net.host.ipv6; }; })
            ];
            routes =
            [
              (mkIf (config.benaryorg.net.host.ipv4 != null) { routeConfig =
              {
                Destination = "0.0.0.0/0";
                Gateway = config.benaryorg.net.host.ipv4Gateway;
              }; })
              (mkIf (config.benaryorg.net.host.ipv6 != null) { routeConfig =
              {
                Destination = "::/0";
                Gateway = config.benaryorg.net.host.ipv6Gateway;
              }; })
            ];
          };
        };
      };
    })
  ]);
}
