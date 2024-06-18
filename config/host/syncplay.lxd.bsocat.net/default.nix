{ config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIXlwb9MouVvrLm49diJxeUktG/HFxS2tedjKMEaYWEi";

  age.secrets.syncplaySalt =
  {
    file = ./secret/service/syncplay/syncplay.lxd.bsocat.net.age;
    owner = "syncplay";
  };

  benaryorg.prometheus.client.enable = true;
  users.groups.syncplay = {};
  users.users.syncplay =
  {
    isSystemUser = true;
    group = "syncplay";
    home = "/var/lib/syncplay";
    createHome = false;
  };
  services.syncplay =
  {
    enable = true;
    certDir = "/run/credentials/syncplay.service";
    user = "syncplay";
    group = "syncplay";
    extraArgs = [ "--isolate-rooms" ];
    saltFile = config.age.secrets.syncplaySalt.path;
  };
  security.acme.certs.${config.networking.fqdn} =
  {
    reloadServices = [ "syncplay.service" ];
    listenHTTP = ":80";
    group = "syncplay";
  };
  systemd.services.syncplay =
  {
    wants = [ "acme-finished-${config.networking.fqdn}.target" ];
    after = [ "acme-finished-${config.networking.fqdn}.target" ];
    serviceConfig.LoadCredential =
    [
      "cert.pem:/var/lib/acme/${config.networking.fqdn}/cert.pem"
      "privkey.pem:/var/lib/acme/${config.networking.fqdn}/key.pem"
      "chain.pem:/var/lib/acme/${config.networking.fqdn}/chain.pem"
    ];
  };
  systemd.tmpfiles.rules = [ "v '/var/lib/syncplay' 0750 syncplay syncplay - -" ];

  system.stateVersion = "24.05";
}
