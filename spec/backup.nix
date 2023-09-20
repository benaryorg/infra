{ nixpkgs, nodes, config, pkgs, lib, options, ... }:
with lib;
{
  options =
  {
    benaryorg.backup =
    {
      role = mkOption
      {
        type = types.enum [ "client" "server" "none" ];
        description = mdDoc
        ''
          In what role to act.
          A `server` provides accesses the clients via SSH and rsyncs their data.
          A `client` will provide SSH access to servers wrapping the rsync process in a sandboxed environment allowing only access to directories which should be synced.
          `none` opts out of the entire module.
        '';
        default = if config.benaryorg.backup.client.directories == [] then "none" else "client";
      };
      tags = mkOption
      {
        type = types.listOf types.str;
        default = [ "default" ];
        description = mdDoc
        ''
          List of tags to use/serve.

          Tags can be added to clients and servers, servers will be usable by all clients containing any of the specified tags.
          This allows for an n:m relation between clients and servers.
          The default is the netwoking domain.
        '';
      };
      client =
      {
        directories = mkOption
        {
          type = types.listOf types.path;
          description = mdDoc
          ''
            List of directories to backup.

            This is not used on the server-side since the visibility of directories is restricted in the client force-command.
          '';
        };
      };
    };
  };

  config =
    let
      cfg = config.benaryorg.backup;
      globalConf = pkgs.callPackage ../conf {};
      hostkey = globalConf.hostkey;
    in
      mkMerge
      [
        (mkIf (cfg.role == "server")
        (
          let
            client = lib.pipe nodes
            [
              # get all the node configs
              builtins.attrValues
              # filter by those which are clients
              (builtins.filter (n: n.config.benaryorg.backup.role == "client"))
              # filter by those which have the local tags
              (builtins.filter (n: any ((flip elem) cfg.tags) n.config.benaryorg.backup.tags))
            ];
          in
            {
              # TODO: create timer and service unit for all clients as well as btrbk config
            }
        ))
        (mkIf (cfg.role == "client")
        (
          let
            client = lib.pipe nodes
            [
              # get all the node configs
              builtins.attrValues
              # filter by those which are servers
              (builtins.filter (n: n.config.benaryorg.backup.role == "server"))
              # filter by those which have the local tags
              (builtins.filter (n: any ((flip elem) cfg.tags) n.config.benaryorg.backup.tags))
            ];
          in
            {
              # TODO: create user with SSH keys and force-command
            }
        ))
      ];
}
