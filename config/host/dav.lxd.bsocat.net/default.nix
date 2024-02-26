{ config, pkgs, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO/e3ex8AhdhIRHPHpiYRz6sUZ1cLn9lOS8FJsu3pV87";

  benaryorg.prometheus.client.enable = true;
  benaryorg.backup.client.directories =
  [
    "/var/lib/xandikos"
  ];

  services =
  {
    xandikos =
    {
      enable = true;
      extraOptions =
      [
        "--autocreate"
        "--current-user-principal" "/benaryorg"
      ];
      nginx =
      {
        enable = true;
        hostName = "dav.benary.org";
      };
    };
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
          locations."/" = { return = "200 \"Meow.\""; extraConfig = "more_set_headers 'content-type: text/plain';"; };
        };
        ${config.services.xandikos.nginx.hostName} =
        {
          enableACME = true;
          forceSSL = true;
          locations."/" =
          {
            proxyWebsockets = true;
            basicAuthFile = pkgs.writers.writeText "xandikos-basic-auth"
            ''
              benaryorg:$2b$08$2SnFBcrMTlue/Md1Gpp0V.MvZ2yYuOxG/me0KPDGvDr3OEqEFhfuS
            '';
          };
        };
      };
    };
  };

  system.stateVersion = "23.11";
}
