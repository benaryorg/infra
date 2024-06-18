{ config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDBX2ygU+eApcIQSWx9GZ7p+u+Zo8ozz529GRwO/sPRY";

  benaryorg.prometheus.client.enable = true;

  services =
  {
    owncast.enable = true;
    nginx =
    {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts =
      {
        ${config.networking.fqdn} =
        {
          enableACME = true;
          forceSSL = true;
          locations."/" =
          {
            proxyPass = "http://localhost:${toString config.services.owncast.port}";
            proxyWebsockets = true;
          };
        };
      };
    };
  };

  system.stateVersion = "24.05";
}
