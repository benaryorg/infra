{ nodes, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEzsNKBz1FTuxlB36W1cCAQ5ZSipBMxEhB8A3CCTpjeL";

  age.secrets.homes3LegoSecret.file = ./secret/lego/hedns/home-s3.xn--idk5byd.net.acme.bsocat.net.age;
  benaryorg.net.type = "manual";
  benaryorg.user.ssh.keys = [ nodes."gnutoo.home.bsocat.net".config.benaryorg.ssh.userkey.benaryorg ];
  benaryorg.prometheus.client.enable = true;

  services =
  {
    ceph =
    {
      enable = true;
      global =
      {
        fsid = "62e93be0-0c5f-4e11-ab8c-e93376a40b87";
        monHost = "v2:[2a0c:b641:a40:0:6efe:54ff:fe48:60b9]:3301/0 v2:[2a0c:b641:a40:0:6efe:54ff:fe48:60b9]:3302/0 v2:[2a0c:b641:a40:0:6efe:54ff:fe48:60b9]:3303/0";

        authClusterRequired = "cephx";
        authServiceRequired = "cephx";
        authClientRequired = "cephx";

        publicNetwork = "2a0c:b641:a40::/48";
        clusterNetwork = "2a0c:b641:a40::/48";
      };

      extraConfig =
      {
        ms_bind_ipv4 = "false";
        ms_bind_ipv6 = "true";

        ms_cluster_mode = "secure";
        ms_service_mode = "secure";
        ms_client_mode = "secure";
        ms_mon_cluster_mode = "secure";
        ms_mon_service_mode = "secure";
        ms_mon_client_mode = "secure";
        rbd_default_map_options = "ms_mode=secure";
      };
      client =
      {
        enable = true;
        extraConfig =
        {
          "client.radosgw.1" =
          {
            rgw_frontends = "beast endpoint=[::1]:7480";
            rgw_resolve_cname = "true";
            rgw_dns_name = "home-s3.xn--idk5byd.net";
          };
        };
      };
      rgw =
      {
        enable = true;
        daemons = [ "radosgw.1" ];
      };
    };
    nginx =
    {
      enable = true;
      # includes proxy_http_version=1.1 (required by request_buffering)
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
        "home-s3.xn--idk5byd.net" =
        {
          serverAliases = [ "*.home-s3.xn--idk5byd.net" ];
          enableACME = true;
          forceSSL = true;
          extraConfig =
          ''
            # avoids request size constraints/temporary files
            proxy_buffering off;
            proxy_request_buffering off;
            client_max_body_size 0;
          '';
          locations."/" =
          {
            proxyPass = "http://localhost:7480";
          };
        };
      };
    };
  };
  security.acme.certs."home-s3.xn--idk5byd.net" =
  {
    dnsProvider = "hurricane";
    credentialsFile = config.age.secrets.homes3LegoSecret.path;
    reloadServices = [ "nginx.service" ];
    group = config.services.nginx.group;
    webroot = null;
  };

  networking.nameservers = [ "2a0c:b641:a40:5::" ];

  system.stateVersion = "24.05";
}
