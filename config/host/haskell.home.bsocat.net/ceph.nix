{ pkgs, lib, config, ... }:
  let
    osd-fsid-map =
    {
      "0" = "e5d0c428-292d-4222-bfed-93054c5839bc";
      "1" = "4f7e6083-aa33-4985-a0dd-26ca93d6946b";
      "2" = "677e1f7e-1fdd-4972-92c6-fc6168515b41";
      "3" = "c63c1604-4a5d-41ba-b101-3ad83a671235";
      "4" = "7e496011-3dcb-446f-886c-e22f65f3ad2d";
      "5" = "14d24025-6106-498c-a01f-f85d3cc8b689";
      "6" = "774df17e-54f8-4eda-8779-d6cb5dfd472b";
      "7" = "e8bd12c8-4385-4d31-bd53-aafe865c6a16";
      "8" = "4274a9ca-b361-4df8-a3ec-30f3a29f819c";
      "9" = "b1b365e7-c26e-4223-8842-dff688977967";
    };
  in
    {
      services.ceph =
      {
        enable = true;
        client.enable = true;
        extraConfig =
        {
          ms_bind_ipv4 = "false";
          ms_bind_ipv6 = "true";
          public_addr = "2a0c:b641:a40:0:6efe:54ff:fe48:60b9";
          cluster_addr = "2a0c:b641:a40:0:6efe:54ff:fe48:60b9";
          ms_cluster_mode = "secure";
          ms_service_mode = "secure";
          ms_client_mode = "secure";
          ms_mon_cluster_mode = "secure";
          ms_mon_service_mode = "secure";
          ms_mon_client_mode = "secure";
          rbd_default_map_options = "ms_mode=secure";
        };
        global =
        {
          fsid = "62e93be0-0c5f-4e11-ab8c-e93376a40b87";
          clusterNetwork = "2a0c:b641:a40::/48";
          # TODO: dynamic
          monInitialMembers = "v2:[2a0c:b641:a40:0:6efe:54ff:fe48:60b9]:3301/0 v2:[2a0c:b641:a40:0:6efe:54ff:fe48:60b9]:3302/0 v2:[2a0c:b641:a40:0:6efe:54ff:fe48:60b9]:3303/0";
          monHost = "v2:[2a0c:b641:a40:0:6efe:54ff:fe48:60b9]:3301/0 v2:[2a0c:b641:a40:0:6efe:54ff:fe48:60b9]:3302/0 v2:[2a0c:b641:a40:0:6efe:54ff:fe48:60b9]:3303/0";
        };

        mon =
        {
          enable = true;
          daemons = [ "0" "1" "2" ];
        };

        osd =
        {
          enable = true;
          daemons = builtins.attrNames osd-fsid-map;
        };

        mds =
        {
          enable = true;
          daemons = [ "a" "b" "c" "d" ];
        };

        mgr =
        {
          enable = true;
          daemons = [ config.networking.fqdn ];
        };
      };

      systemd.services =
        let
          osd-name = id: "ceph-osd-${id}";
          osd-pre-start = id:
          [
            "!${config.services.ceph.osd.package.out}/bin/ceph-volume lvm activate --bluestore ${id} ${osd-fsid-map.${id}} --no-systemd"
            "${config.services.ceph.osd.package.lib}/libexec/ceph/ceph-osd-prestart.sh --id ${id} --cluster ${config.services.ceph.global.clusterName}"
          ];
          osd-post-stop = id:
          [
            "!${config.services.ceph.osd.package.out}/bin/ceph-volume lvm deactivate ${id} ${osd-fsid-map.${id}}"
          ];
          map-osd = id:
          {
            name = osd-name id;
            value =
            {
              serviceConfig.ExecStartPre = lib.mkForce (osd-pre-start id);
              serviceConfig.ExecStopPost = osd-post-stop id;
              serviceConfig.TemporaryFileSystem = lib.mkOrder 1000 [ "/var/lib/ceph/osd/ceph-${id}:size=64M,nostrictatime,noatime" ];
              unitConfig.ConditionPathExists = lib.mkForce [];
              unitConfig.StartLimitBurst = lib.mkForce 4;
              path = with pkgs; [ util-linux lvm2 cryptsetup ];
            };
          };
        in
          (lib.pipe config.services.ceph.osd.daemons
          [
            (builtins.map map-osd)
            builtins.listToAttrs
          ])
            //
          {
            stunnel =
            {
              wants = [ "acme-finished-${config.networking.fqdn}.target" ];
              after = [ "acme-finished-${config.networking.fqdn}.target" ];
              serviceConfig.LoadCredential =
              [
                "cert.pem:/var/lib/acme/${config.networking.fqdn}/cert.pem"
                "key.pem:/var/lib/acme/${config.networking.fqdn}/key.pem"
              ];
            };
          };

      services.stunnel.servers =
      {
        ceph =
        {
          accept = ":::19283";
          # FIXME? maybe make this more stable?
          connect = 9283;
          cert = "/run/credentials/stunnel.service/cert.pem";
          key = "/run/credentials/stunnel.service/key.pem";
          CAFile = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          # do the dynamic thing?
          checkHost = "prometheus.lxd.bsocat.net";
          sslVersion = "TLSv1.3";
          verifyChain = true;
        };
      };

      benaryorg.prometheus.client.mocks.ceph =
      {
        port = 19283;
      };
    }
