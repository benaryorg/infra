{ pkgs, lib, config, ... }:
{
  benaryorg.net.type = "manual";
  benaryorg.net.resolver = "none";

  boot.kernelModules = [ "r8169" ];
  services.bird2 =
  {
    enable = true;
    config = builtins.readFile ./file/bird.conf;
  };
  networking.nameservers = [ "2a0c:b641:a40:5::" ];
  systemd.services.bird2.before = lib.mkAfter [ "network-online.target" ];
  systemd.services.bird2.wantedBy = [ "network-online.target" ];
  systemd.services.bird2.after = lib.mkAfter [ "systemd-networkd-wait-online.service" ];
  systemd.network =
  {
    enable = true;
    networks =
    {
      "40-loopback" =
      {
        enable = true;
        name = "lo";
        DHCP = "no";
        addresses =
        [
          { addressConfig = { Address = "2a0c:b641:a40:0:264b:feff:fe90:7474"; }; }
        ];
      };
      "50-mlx" =
      {
        enable = true;
        name = "enp5s0*";
        dns = [ "2a0c:b641:a40:5::" ];
        DHCP = "no";
        linkConfig =
        {
          RequiredFamilyForOnline = "ipv6";
          RequiredForOnline = "degraded";
          ActivationPolicy = "always-up";
          MTUBytes = "9000";
        };
        networkConfig =
        {
          IPv6AcceptRA = false;
          IPForward = "ipv6";
          DNSDefaultRoute = true;
          KeepConfiguration = true;
        };
      };
      "50-intel" =
      {
        enable = true;
        name = "enp6s0 enp7s0";
        DHCP = "no";
        linkConfig =
        {
          RequiredForOnline = false;
          ActivationPolicy = "always-up";
          MTUBytes = "1500";
        };
        networkConfig =
        {
          IPv6AcceptRA = false;
          IPForward = "ipv6";
          KeepConfiguration = true;
        };
      };
      "80-nat464" =
      {
        enable = true;
        name = "br1";
        DHCP = "no";
        addresses =
        [
          { addressConfig = { Address = "10.0.0.2/24"; }; }
          { addressConfig = { Address = "2a0c:b641:a40:2::3/128"; }; }
        ];
        gateway = [ "10.0.0.1" ];
        linkConfig =
        {
          RequiredForOnline = false;
          ActivationPolicy = "always-up";
        };
        networkConfig =
        {
          IPv6AcceptRA = false;
          IPForward = "ipv4";
          ConfigureWithoutCarrier = true;
          KeepConfiguration = true;
        };
      };
      "80-virt" =
      {
        enable = true;
        name = "br3";
        DHCP = "no";
        addresses =
        [
          { addressConfig = { Address = "2a0c:b641:a40:2::1/96"; }; }
        ];
        linkConfig =
        {
          RequiredForOnline = false;
          ActivationPolicy = "always-up";
        };
        networkConfig =
        {
          IPv6AcceptRA = false;
          IPForward = "ipv4";
          ConfigureWithoutCarrier = true;
          KeepConfiguration = true;
        };
      };
    };
    netdevs =
    {
      "80-nat464" =
      {
        netdevConfig = { Kind = "bridge"; Name = "br1"; MTUBytes = "1392"; };
      };
      "80-virt" =
      {
        netdevConfig = { Kind = "bridge"; Name = "br3"; MTUBytes = "9000"; };
      };
    };
  };
}
