{ lib, config, ... }:
{
  benaryorg.net.type = "manual";
  benaryorg.net.resolver = "none";

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
          { addressConfig = { Address = "2a0c:b641:a40:0:6efe:54ff:fe48:60b9/128"; }; }
        ];
      };
      "50-external" =
      {
        enable = true;
        name = "enp21s0";
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
    };
  };
}
