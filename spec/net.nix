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
        type = types.enum [ "container" "host" "none" ];
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
      services =
      {
        unbound.enable = config.benaryorg.net.unbound.enable;
        rdnssd.enable = config.benaryorg.net.rdnssd.enable;
      };
    }
    (mkIf (config.benaryorg.net.type == "host")
    {
      networking.interfaces =
      {
        "${config.benaryorg.net.host.primaryInterface}" =
          let
            splitAddr = addr: (
              pipe addr
              [
                (splitString "/")
                (list: { address = (builtins.head list); prefixLength = (pipe list [ reverseList builtins.head toInt]); })
              ]
            );
          in
        {
          ipv4 = mkIf (config.benaryorg.net.host.ipv4 != null)
          {
            addresses = [ (splitAddr config.benaryorg.net.host.ipv4) ];
            routes = [ { address = "0.0.0.0"; prefixLength = 0; via = config.benaryorg.net.host.ipv4Gateway; } ];
          };
          ipv6 = mkIf (config.benaryorg.net.host.ipv6 != null)
          {
            addresses = [ (splitAddr config.benaryorg.net.host.ipv6) ];
            routes = [ { address = "::"; prefixLength = 0; via = config.benaryorg.net.host.ipv6Gateway; } ];
          };
        };
      };
    })
  ]);
}
