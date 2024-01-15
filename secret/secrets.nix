let
  flake = builtins.getFlake (builtins.toPath ./..);
  nodes = flake.outputs.nixosConfigurations;
  lib = flake.inputs.nixpkgs.lib;
  conf = import ../conf { inherit lib; };
  addJumphostUser = list: list ++ [ conf.sshkey."benaryorg@shell.cloud.bsocat.net" ];
in
  lib.pipe nodes
  [
    builtins.attrValues
    (builtins.map (n:
      lib.pipe n.config.age.secrets
      [
        builtins.attrValues
        (builtins.map (secret:
          {
            file = lib.pipe secret.file
            [
              builtins.toPath
              (lib.removePrefix (builtins.toPath flake))
              (lib.removePrefix "/secret/")
            ];
            key = n.config.benaryorg.ssh.hostkey;
          }
        ))
      ]
    ))
    lib.flatten
    (builtins.groupBy ({ file, ... }: file))
    (lib.mapAttrs (_: keys:
      lib.pipe keys
      [
        (builtins.map (builtins.getAttr "key"))
        addJumphostUser
        lib.unique
      ]
    ))
  ]
