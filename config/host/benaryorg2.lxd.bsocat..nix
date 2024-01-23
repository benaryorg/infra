{ name, nodes, pkgs, lib, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPXO1VPYJ5YfvCT4wvTWauSSLtmHS2gG8jh7RQyu6hy+";

  age.secrets.benaryorgLegoSecret.file = ../../secret/lego/hedns/benary.org.age;
  benaryorg.prometheus.client.enable = true;
  benaryorg.website.enable = true;
  services.nginx.virtualHosts.${config.networking.fqdn} =
  {
    enableACME = true;
    forceSSL = true;
    locations."/" = { return = "200 \"Meow.\""; extraConfig = "more_set_headers 'content-type: text/plain';"; };
  };
  security.acme.certs."benary.org" =
  {
    dnsProvider = "hurricane";
    credentialsFile = config.age.secrets.benaryorgLegoSecret.path;
    reloadServices = [ "nginx.service" ];
    group = config.services.nginx.group;
  };

  system.stateVersion = "23.11";
}
