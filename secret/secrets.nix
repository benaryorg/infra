let
  nixpkgs = import <nixpkgs> {};
  lib = nixpkgs.lib;
  conf = import ../conf { inherit lib; };
  addJumphost = builtins.mapAttrs (name: value: value // { publicKeys = lib.unique (value.publicKeys ++ [ conf.sshkey."benaryorg@shell.cloud.bsocat.net" ]); });
in
  addJumphost
  {
    "lego/hedns/shell.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."shell.cloud.bsocat.net" ];
    "lego/hedns/lxd6.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."lxd6.cloud.bsocat.net" ];
    "lego/hedns/lxd5.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."lxd5.cloud.bsocat.net" ];
    "lego/hedns/lxd4.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."lxd4.cloud.bsocat.net" ];
    "lego/hedns/lxd3.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."lxd3.cloud.bsocat.net" ];
    "lego/hedns/lxd2.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."lxd2.cloud.bsocat.net" ];
    "lego/hedns/lxd1.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."lxd1.cloud.bsocat.net" ];
    "lego/hedns/benary.org.age".publicKeys = [ conf.hostkey."benaryorg1.lxd.bsocat.net" conf.hostkey."benaryorg2.lxd.bsocat.net" conf.hostkey."benaryorg3.lxd.bsocat.net" ];
    "lego/hedns/home-s3.xn--idk5byd.net.acme.bsocat.net.age".publicKeys = [ conf.hostkey."radosgw1.home.bsocat.net" ];
    "service/prosody/xmpp.lxd.bsocat.net.age".publicKeys = [ conf.hostkey."xmpp.lxd.bsocat.net" ];
    "service/syncplay/syncplay.lxd.bsocat.net.age".publicKeys = [ conf.hostkey."syncplay.lxd.bsocat.net" ];
    "service/grafana/prometheus.lxd.bsocat.net/admin_user.age".publicKeys = [ conf.hostkey."prometheus.lxd.bsocat.net" ];
    "service/grafana/prometheus.lxd.bsocat.net/admin_pass.age".publicKeys = [ conf.hostkey."prometheus.lxd.bsocat.net" ];
    "service/grafana/prometheus.lxd.bsocat.net/secret.age".publicKeys = [ conf.hostkey."prometheus.lxd.bsocat.net" ];
    "service/xmpp/xmpp.lxd.bsocat.net/user/monitoring@benary.org.age".publicKeys = [ conf.hostkey."prometheus.lxd.bsocat.net" ];
    "build/nixos-builder.shell.bsocat.net.age".publicKeys = [ conf.hostkey."nixos-builder.shell.bsocat.net" ];
    "build/nixos.home.bsocat.net.age".publicKeys = [ conf.hostkey."nixos.home.bsocat.net" ];
  }
