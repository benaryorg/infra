{ config, ... }:
{
  age.secrets.wg64 = { file = ./secret/wireguard/mir.home.bsocat.net/wg64.age; mode = "0400"; };
  age.secrets.wg4 = { file = ./secret/wireguard/mir.home.bsocat.net/wg4.age; mode = "0640"; owner = "root"; group = "systemd-network"; };

  systemd.network =
  {
    netdevs =
    {
      "80-wg4" =
      {
        netdevConfig =
        {
          Kind = "wireguard";
          Name = "wg4";
          MTUBytes = "1332";
        };
        wireguardConfig =
        {
          PrivateKeyFile = config.age.secrets.wg4.path;
          ListenPort = 51281;
        };
        wireguardPeers =
        [
          {
            wireguardPeerConfig =
            {
              PublicKey = "oO1quiYKv9V+pPkBkQxD0Uoim9z4apKlk9Jo/zbNbSA=";
              AllowedIPs = [ "0.0.0.0/0" ];
              Endpoint = "lxd1.cloud.bsocat.net:51281";
            };
          }
        ];
      };
    };
    networks =
    {
      "80-wg4" =
      {
        enable = true;
        name = "wg4";
        DHCP = "no";
        linkConfig =
        {
          RequiredForOnline = false;
          ActivationPolicy = "always-up";
        };
        addresses =
        [
          { addressConfig = { Address = "151.80.112.84/32"; }; }
        ];
        routes =
        [
          { routeConfig = { Gateway = "169.254.0.1"; GatewayOnLink = true; Destination = "0.0.0.0/0"; }; }
        ];
        networkConfig =
        {
          IPv6AcceptRA = false;
          IPForward = "ipv4";
          ConfigureWithoutCarrier = true;
          KeepConfiguration = true;
        };
      };
    };
  };

  networking.wg-quick.interfaces.wg64 =
  {
    address = [ "10.192.122.6/24" ];
    listenPort = 51280;
    mtu = 1328;
    peers = [
      {
        publicKey = "uOL70OXFnffvQ3KZ8Ozz+3R//5gFSphNIkdPI3UiEgo=";
        allowedIPs = [ "10.192.122.1/32" ];
      }
      {
        publicKey = "i2MCZlH19aFTaORVLLMOEpQcrRW+VHpekxykiBrWVws=";
        allowedIPs = [ "10.192.122.2/32" ];
      }
      {
        publicKey = "JRk6muF/Dfn9+wzjl+eQCz3hto1rnPmw4t9n7NxcI0E=";
        allowedIPs = [ "10.192.122.3/32" ];
      }
      {
        publicKey = "mJFupDqcQ2StPYq9jzjtFEUZOHRc+stlYz8w3J4geX4=";
        allowedIPs = [ "10.192.122.4/32" ];
      }
      {
        publicKey = "xDNzwbL0cByG5xmRKYlo3HXLXGulLjFWow8MCqrWRBo=";
        allowedIPs = [ "10.192.122.6/32" ];
        # do not connect to self
        #endpoint = "mir.home.bsocat.net:51280";
      }
      {
        publicKey = "qADlb218CYeFlqiqNq8S1c1hTj2sEhDd4YH9o2wvGk4=";
        allowedIPs = [ "10.192.122.7/32" ];
      }
      {
        publicKey = "E/SIkPNFNcGAQdMqM6HDVWRWHlXA9k4TNPaR4eph0H4=";
        allowedIPs = [ "10.192.122.8/32" ];
      }
      {
        publicKey = "2/zQVx7r4msbC00SUKLVTWdIB7PwpBQytQiJuqp0sVY=";
        allowedIPs = [ "10.192.122.9/32" ];
      }
      {
        publicKey = "LLDr82Put5tOSkkyxOyFAePq7+bNSkiOtScXkA+Hokw=";
        allowedIPs = [ "10.192.122.10/32" ];
      }
    ];
    privateKeyFile = config.age.secrets.wg64.path;
  };
}
