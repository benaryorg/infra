{ nodes, config, pkgs, lib, options, ... }:
{
  options =
  {
    benaryorg.backup =
    {
      role = lib.mkOption
      {
        type = lib.types.enum [ "client" "server" "none" ];
        description = lib.mdDoc
        ''
          In what role to act.
          A `server` provides accesses the clients via SSH and rsyncs their data.
          A `client` will provide SSH access to servers wrapping the rsync process in a sandboxed environment allowing only access to directories which should be synced.
          `none` opts out of the entire module.
        '';
        default = if config.benaryorg.backup.client.directories == [] then "none" else "client";
        defaultText = lib.mdDoc ''If {option}`benaryorg.backup.client.directorie` is an empty list then `"none"` otherwise `"client"`.'';
      };
      tags = lib.mkOption
      {
        type = lib.types.listOf lib.types.str;
        default = [ "default" ];
        description = lib.mdDoc
        ''
          List of tags to use/serve.

          Tags can be added to clients and servers, servers will be usable by all clients containing any of the specified tags.
          This allows for an n:m relation between clients and servers.
          The default is the netwoking domain.
        '';
      };
      client =
      {
        directories = lib.mkOption
        {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = lib.mdDoc
          ''
            List of directories to backup.

            This is not used on the server-side since the visibility of directories is restricted in the client force-command.
          '';
        };
        excludes = lib.mkOption
        {
          type = lib.types.listOf lib.types.str;
          default = [ "/nix" ];
          description = lib.mdDoc
          ''
            List of rsync style patterns to exclude.

            This is used on the server-side.
            For legacy clients (not NixOS) this is the primary method of controlling the backup source.
            On NixOS this should include only the default {file}`/nix` which has to be visible to the rsync process to actually run the rsync command.
          '';
        };
      };
    };
  };

  config =
    let
      cfg = config.benaryorg.backup;
    in
      lib.mkMerge
      [
        (lib.mkIf (cfg.role == "server")
        (
          let
            client = lib.pipe nodes
            [
              # get all the node configs
              builtins.attrValues
              # filter by those which are clients
              (builtins.filter (n: n.config.benaryorg.backup.role == "client"))
              # filter by those which have the local tags
              (builtins.filter (n: builtins.any ((lib.flip builtins.elem) cfg.tags) n.config.benaryorg.backup.tags))
            ];
            sshConfig = pkgs.writers.writeText "backup-ssh-config"
            ''
              UpdateHostKeys no
              TCPKeepAlive yes
              KeepAlive yes
              ConnectTimeout 8
              ForwardAgent no
              PreferredAuthentications publickey
              User backup
              IdentityFile /etc/ssh/ssh_host_ed25519_key
              UserKnownHostsFile none
            '';
            btrbkConfig = node: pkgs.writers.writeText "backup-btrbk-remote-${node.config.networking.fqdn}.conf"
            ''
              timestamp_format long-iso
              stream_buffer 256m
              snapshot_create always
              incremental yes
              preserve_hour_of_day 0
              preserve_day_of_week monday
              snapshot_preserve_min latest
              snapshot_preserve 25h 8d 5w 13m 4y
              volume /var/lib/backup/${node.config.networking.fqdn}
                subvolume rootfs
            '';
          in
            {
              systemd.services = lib.pipe client
              [
                (builtins.map (node:
                {
                  name = let name = builtins.replaceStrings [ "." ] [ "-" ] node.config.networking.fqdn; in "backup-run-${name}";
                  value =
                  {
                    description = "backup run for ${node.config.networking.fqdn}";
                    startAt = "hourly";
                    wants = [ "network-online.target" ];
                    after = [ "network-online.target" ];
                    script =
                    ''
                      if
                          ${pkgs.rsync}/bin/rsync \
                              -e "${pkgs.openssh}/bin/ssh -F ${sshConfig}" -a --numeric-ids --delete \
                      ${builtins.concatStringsSep "\n" (builtins.map (dir: "        " + (lib.escapeShellArgs [ "--exclude" dir ]) + " \\") node.config.benaryorg.backup.client.excludes)}
                              ${node.config.networking.fqdn}:/ /var/lib/backup/${node.config.networking.fqdn}/rootfs/
                      then
                          true
                      else
                          ret=$?
                          # return code 24 is fine, it just means that stuff changed while syncing
                          (( ret == 24 ))
                      fi

                      ${pkgs.btrbk}/bin/btrbk run --config ${btrbkConfig node}
                    '';
                  };
                }))
                builtins.listToAttrs
              ];
              systemd.tmpfiles.rules = lib.mkAfter (
                [
                  "v '/var/lib/backup' 0755 root root - -"
                ]
                ++ lib.flatten (builtins.map (node:
                  [
                    "d '/var/lib/backup/${node.config.networking.fqdn}' 0750 root root - -"
                    "v '/var/lib/backup/${node.config.networking.fqdn}/rootfs' 0750 root root - -"
                  ]) client)
              );
            }
        ))
        (lib.mkIf (cfg.role == "client")
        (
          let
            server = lib.pipe nodes
            [
              # get all the node configs
              builtins.attrValues
              # filter by those which are servers
              (builtins.filter (n: n.config.benaryorg.backup.role == "server"))
              # filter by those which have the local tags
              (builtins.filter (n: builtins.any ((lib.flip builtins.elem) cfg.tags) n.config.benaryorg.backup.tags))
            ];
            backupWrapper = pkgs.writers.writeBash "backup-wrapper"
            ''
              set -eo pipefail
              test "$1" = "rsync"
              shift

              exec ${pkgs.bubblewrap}/bin/bwrap \
                  --die-with-parent \
                  --unshare-ipc --unshare-pid --unshare-net --unshare-uts --unshare-cgroup --new-session \
                  --chdir / \
                  --clearenv --setenv PATH ${pkgs.rsync}/bin \
                  --ro-bind /nix /nix \
              ${builtins.concatStringsSep "\n" (builtins.map (dir: "    " + (lib.escapeShellArgs [ "--ro-bind" dir dir ]) + " \\") cfg.client.directories)}
                  ${pkgs.rsync}/bin/rsync "''${@}"
            '';
            forceCommand = pkgs.writers.writeBash "backup-force-command"
            ''
              set -eo pipefail
              exec sudo ${backupWrapper} $SSH_ORIGINAL_COMMAND
            '';
          in
            {
              users.groups.backup = {};
              users.users.backup =
              {
                isSystemUser = true;
                group = "backup";
                home = "/var/lib/backup";
                shell = "/bin/sh";
                createHome = true;
                openssh.authorizedKeys.keys = builtins.map (node: ''restrict,command="${forceCommand}" ${node.config.benaryorg.ssh.hostkey}'') server;
              };
              security.sudo.extraRules = lib.mkAfter
              [
                {
                  users = [ "backup" ];
                  commands =
                  [
                    { command = toString backupWrapper; options = [ "NOPASSWD" ]; }
                  ];
                }
              ];
            }
        ))
      ];
}
