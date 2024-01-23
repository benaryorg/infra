let
  flake = builtins.getFlake (builtins.toPath ./.);
  nodes = flake.outputs.nixosConfigurations;
  lib = flake.inputs.nixpkgs.lib;
  addJumphostUser = list: list ++ [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrKgj+479k+nZjVKAeVnh0clxh6MUuEmY0BTtaNMDi5" ];
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
        (keys: { publicKeys = keys; })
      ]
    ))
  ]
