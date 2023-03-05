let
  nixpkgs = import <nixpkgs> {};
  lib = nixpkgs.lib;
  conf = import ../conf { inherit lib; };
  addJumphost = builtins.mapAttrs (name: value: value // { publicKeys = lib.unique (value.publicKeys ++ [ conf.sshkey."benaryorg@shell.cloud.bsocat.net" ]); });
in
  addJumphost
  {
    "lego/hedns/lxd6.cloud.bsocat.net.age".publicKeys = [ conf.hostkey."lxd6.cloud.bsocat.net" ];
  }
