let
  nixpkgs = import <nixpkgs> {};
  lib = nixpkgs.lib;
  conf = import ../conf { inherit lib; };
  addJumphost = builtins.mapAttrs (name: value: value // { publicKeys = lib.unique (value.publicKeys ++ [ conf.sshkey."benaryorg@shell.cloud.bsocat.net" ]); });
in
  addJumphost
  {
    "lego/hedns/lxd6.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."lxd6.cloud.bsocat.net" ];
    "lego/hedns/lxd5.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."lxd5.cloud.bsocat.net" ];
    "lego/hedns/lxd4.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."lxd4.cloud.bsocat.net" ];
    "lego/hedns/lxd3.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."lxd3.cloud.bsocat.net" ];
    "lego/hedns/lxd2.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."lxd2.cloud.bsocat.net" ];
    "lego/hedns/lxd1.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."lxd1.cloud.bsocat.net" ];
    "service/prosody/xmpp.lxd.bsocat.net.age".publicKeys = [ conf.hostkey."xmpp.lxd.bsocat.net" ];
    "service/syncplay/syncplay.lxd.bsocat.net.age".publicKeys = [ conf.hostkey."syncplay.lxd.bsocat.net" ];
    "service/grafana/prometheus.lxd.bsocat.net/admin_user.age".publicKeys = [ conf.hostkey."prometheus.lxd.bsocat.net" ];
    "service/grafana/prometheus.lxd.bsocat.net/admin_pass.age".publicKeys = [ conf.hostkey."prometheus.lxd.bsocat.net" ];
    "service/grafana/prometheus.lxd.bsocat.net/secret.age".publicKeys = [ conf.hostkey."prometheus.lxd.bsocat.net" ];
    "build/nixos-builder.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."nixos-builder.cloud.bsocat.net" ];
    "build/nixos.home.bsocat.net.age".publicKeys = [ conf.hostkey."nixos.home.bsocat.net" ];
  }
