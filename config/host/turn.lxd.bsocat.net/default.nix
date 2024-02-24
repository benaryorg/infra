{ lib, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDRtlLH3L15UCWuEY40YsBuCr9bSr8X4Sk5omHRbl4YE";

  age.secrets.coturnLegoSecret.file = ./secret/lego/hedns/turn-static.svc.benary.org.age;
  age.secrets.coturnSecret =
  {
    file = ./secret/service/coturn/turn.lxd.bsocat.net.age;
    owner = config.systemd.services.coturn.serviceConfig.User;
  };
  benaryorg.prometheus.client.enable = true;
  security.acme.certs =
  {
    ${config.networking.fqdn}.listenHTTP = ":80";
    "turn-static.svc.benary.org" =
    {
      dnsProvider = "hurricane";
      credentialsFile = config.age.secrets.coturnLegoSecret.path;
      reloadServices = [ "coturn.service" ];
      group = config.systemd.services.coturn.serviceConfig.Group;
    };
  };
  systemd.network.networks."40-ipv4".enable = lib.mkForce false;
  services =
  {
    coturn =
    {
      enable = true;
      static-auth-secret-file = config.age.secrets.coturnSecret.path;
      secure-stun = true;
      no-cli = true;
      realm = "turn-static.svc.benary.org";
      cert = "/var/lib/acme/turn-static.svc.benary.org/cert.pem";
      pkey = "/var/lib/acme/turn-static.svc.benary.org/key.pem";
    };
  };

  system.stateVersion = "23.11";
}
