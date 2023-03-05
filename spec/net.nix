{ config, pkgs, lib, options, ... }:
with lib;
{
  options =
  {
    benaryorg.net =
    {
      unbound =
      {
        enable = mkOption
        {
          default = config.benaryorg.hardware.vendor != "container";
          description = "Whether to enable local unbound.";
          type = types.bool;
        };
      };
      rdnssd =
      {
        enable = mkOption
        {
          default = config.benaryorg.hardware.vendor == "container";
          description = "Whether to enable rdnssd.";
          type = types.bool;
        };
      };
    };
  };

  config =
  {
    networking =
    {
      firewall.enable = false;
      wireguard.enable = false;
      tempAddresses = "disabled";
      useDHCP = false;
    };
    services =
    {
      unbound.enable = config.benaryorg.net.unbound.enable;
      rdnssd.enable = config.benaryorg.net.rdnssd.enable;
    };
  };
}
