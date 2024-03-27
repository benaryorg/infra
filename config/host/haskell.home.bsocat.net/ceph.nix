{ pkgs, lib, config, ... }:
  let
    osd-fsid-map =
    {
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
          monInitialMembers = "v2:[2a0c:b641:a40::264b:feff:fe90:7474]:3301/0 v2:[2a0c:b641:a40::264b:feff:fe90:7474]:3302/0 v2:[2a0c:b641:a40::264b:feff:fe90:7474]:3303/0";
          monHost = "v2:[2a0c:b641:a40::264b:feff:fe90:7474]:3301/0 v2:[2a0c:b641:a40::264b:feff:fe90:7474]:3302/0 v2:[2a0c:b641:a40::264b:feff:fe90:7474]:3303/0";
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
    }
