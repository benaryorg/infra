let
  nixpkgs = import <nixpkgs> {};
  lib = nixpkgs.lib;
  conf = import ../conf { inherit lib; };
  addJumphost = builtins.mapAttrs (name: value: value // { publicKeys = lib.unique (value.publicKeys ++ [ conf.sshkey."benaryorg@shell.cloud.bsocat.net" ]); });
in
  addJumphost
  {
    "lego/hedns/lxd6.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."lxd6.cloud.bsocat.net" ];
    "lego/hedns/lxd4.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."lxd4.cloud.bsocat.net" ];
    "lego/hedns/lxd3.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."lxd3.cloud.bsocat.net" ];
    "lego/hedns/lxd2.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."lxd2.cloud.bsocat.net" ];
    "lego/hedns/lxd1.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."lxd1.cloud.bsocat.net" ];
    "service/syncplay/syncplay.lxd.bsocat.net.age".publicKeys = [ conf.hostkey."syncplay.lxd.bsocat.net" ];
  }
