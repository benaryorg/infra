{ nodes, pkgs, lib, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPDCg36Iu+EzJhyUNSPldV+G8q4p8l9JWPT0nbG2XXCw";

  age.secrets.prosodyLegoSecret.file = ./secret/service/prosody/xmpp.lxd.bsocat.net.age;
  age.secrets.coturnSecret =
  {
    file = nodes."turn.lxd.bsocat.net".config.age.secrets.coturnSecret.file;
    owner = config.services.prosody.user;
  };
  benaryorg.prometheus.client.enable = true;
  benaryorg.prometheus.client.mocks.prosody =
  {
    port = 15280;
  };
  benaryorg.backup.client.directories = [ "/var/lib/prosody" ];
  security.acme.certs =
  {
    ${config.networking.fqdn} =
    {
      listenHTTP = ":80";
      reloadServices = [ "prosody.service" ];
      group = config.services.prosody.group;
    };
    "benary.org" =
    {
      dnsProvider = "hurricane";
      credentialsFile = config.age.secrets.prosodyLegoSecret.path;
      reloadServices = [ "prosody.service" ];
      group = config.services.prosody.group;
      extraDomainNames = [ "conference.benary.org" ];
    };
  };
  services =
  {
    prosody =
    {
      enable = true;
      admins = [ "binary@benary.org" ];
      allowRegistration = false;
      authentication = "internal_hashed";
      c2sRequireEncryption = true;
      s2sRequireEncryption = true;
      s2sSecureAuth = true;
      extraConfig =
      ''
        unbound = {
          resolvconf = true;
          hoststxt = true;
          forward = { "127.0.0.53" };
        };

        turn_external_host = "turn-static.svc.benary.org"
        turn_external_port = 3478
        turn_external_secret = io.open("${config.age.secrets.coturnSecret.path}","r"):read()

        -- FIXME: prosody cannot be convinced to do SNI for both the hostname and the virtualhosts
        -- it will send connection refused for the virtualhost's domains under some circumstances
        -- to sum up my experience: prosody *really* wants you to use their certmanager which.… No.
        --c2s_direct_tls_ports = { 5223, }
        --s2s_direct_tls_ports = { 5270, }

        http_max_content_size = 1024 * 1024 * 1024
        statistics = "internal"
        statistics_interval = "manual"
      '';
      ssl = { cert = "/var/lib/acme/${config.networking.fqdn}/cert.pem"; key = "/var/lib/acme/${config.networking.fqdn}/key.pem"; };
      virtualHosts = lib.mkForce
      {
        "benary.org" =
        {
          enabled = true;
          domain = "benary.org";
          ssl = { cert = "/var/lib/acme/benary.org/cert.pem"; key = "/var/lib/acme/benary.org/key.pem"; };
        };
      };
      uploadHttp =
      {
        domain = "xmpp.lxd.bsocat.net";
        uploadFileSizeLimit = "1024 * 1024 * 512";
        uploadExpireAfter = "60 * 60 * 24 * 7 * 4";
        httpUploadPath = "/var/lib/prosody/http_upload";
      };
      muc =
      [
        {
          domain = "conference.benary.org";
          restrictRoomCreation = "local";
        }
      ];
      modules =
      {
        admin_adhoc = false;
        http_files = false;
        dialback = false;
      };
      extraModules = [ "turn_external" "http_openmetrics" ];
      disco_items = [ { url = "xmpp.lxd.bsocat.net"; description = "http upload service"; } ];
    };
    stunnel =
    {
      enable = true;
      servers.prometheusMock-prosody =
      {
        accept = ":::15280";
        connect = 5280;
        cert = "/run/credentials/stunnel.service/cert.pem";
        key = "/run/credentials/stunnel.service/key.pem";

        CAFile = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

        checkHost =
          let
            tags = config.benaryorg.prometheus.client.tags;
            clients = lib.pipe nodes
            [
              # get all the node configs
              builtins.attrValues
              # filter by those which have the prometheus server
              (builtins.filter (n: n.config.benaryorg.prometheus.server.enable))
              # filter by those which have the local tags
              (builtins.filter (n: builtins.any ((lib.flip builtins.elem) tags) n.config.benaryorg.prometheus.server.tags))
            ];
          in
            # use the first server
            # FIXME: https://github.com/NixOS/nixpkgs/issues/221884
            (builtins.head clients).config.networking.fqdn;

        # FIXME: https://github.com/NixOS/nixpkgs/issues/221884
        #socket = [ "l:TCP_NODELAY=1" "r:TCP_NODELAY=1" ];
        sslVersion = "TLSv1.3";

        verifyChain = true;
      };
    };
  };

  system.stateVersion = "23.11";
}
