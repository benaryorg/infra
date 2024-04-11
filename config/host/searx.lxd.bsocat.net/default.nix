{ benaryorg-flake, pkgs, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJEH2iuMvXZM+P+0kSEGou1pbslPS+Vj8u4xVhF9TKp";

  age.secrets.searxEnv =
  {
    file = ./secret/service/searx/searx.lxd.bsocat.net/env.age;
    owner = "searx";
  };

  benaryorg.prometheus.client.enable = true;

  services =
  {
    # FIXME: https://github.com/searxng/searxng/issues/3227
    searx.package = benaryorg-flake.inputs.nixpkgs-unstable.legacyPackages.${config.nixpkgs.system}.searxng.override { inherit (pkgs) python3; };
    searx =
    {
      enable = true;
      redisCreateLocally = true;
      runInUwsgi = true;
      environmentFile = config.age.secrets.searxEnv.path;

      settings =
      {
        server =
        {
          secret_key = "@SEARXNG_SECRET@";
          base_url = "https://${config.networking.fqdn}/";
          method = "GET";
        };
        general =
        {
          debug = false;
          instance_name = "Katzearx";
        };
        ui =
        {
          query_in_title = true;
          infinite_scroll = true;
        };
      };
      limiterSettings =
      {
        real_ip =
        {
          x_for = 1;
          ipv4_prefix = 32;
          ipv6_prefix = 56;
        };
      };
      uwsgiConfig =
      {
        disable-logging = true;
        http = "[::1]:8080";
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
          locations."/" =
          {
            proxyPass = "http://${config.services.searx.uwsgiConfig.http}";
            proxyWebsockets = true;
          };
        };
      };
    };
  };

  system.stateVersion = "23.11";
}
