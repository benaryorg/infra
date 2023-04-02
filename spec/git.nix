{ config, pkgs, lib, options, ... }:
with lib;
{
  options =
  {
    benaryorg.git =
    {
      enable = mkOption
      {
        default = false;
        description = "Whether to enable git server functionality.";
        type = types.bool;
      };
      adminkey = mkOption
      {
        description = "Gitolite admin SSH key.";
        type = types.str;
      };
      mirror = mkOption
      {
        description = "List of repositories to mirror.";
        default = {};
        example = { nixpkgs = { url = "https://github.com/NixOS/nixpkgs.git"; }; };
        type = types.attrsOf (types.submodule ({ name, config, ...}:
        {
          options =
          {
            name = mkOption
            {
              description = "Name of the public repository in gitolite.";
              type = types.str;
              default = name;
            };
            interval = mkOption
            {
              description = "Interval of update.";
              default = "hourly";
              type = types.str;
            };
            url = mkOption
            {
              description = "URl of the repository for initial clone.";
              type = types.str;
            };
          };
        }));
      };
    };
  };

  config = mkIf config.benaryorg.git.enable
  {
    services =
    {
      gitolite =
      {
        enable = true;
        adminPubkey = config.benaryorg.git.adminkey;
        extraGitoliteRc =
        ''
          $RC{UMASK} = 0027;
          $RC{SITE_INFO} = "${config.networking.fqdn} by Katze";
          push( @{$RC{ENABLE}}, 'D' );
          push( @{$RC{ENABLE}}, 'desc' );
          push( @{$RC{ENABLE}}, 'help' );
        '';
        group = "git";
        user = "git";
      };
      nginx =
      {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        virtualHosts =
        {
          ${config.networking.fqdn} =
          {
            forceSSL = true;
            enableACME = true;
            locations."/" =
            {
              proxyPass = "http://localhost:8000";
            };
          };
        };
      };
    };
    systemd.services =
      {
        klaus =
          let
            klausGunicorn = pkgs.python3.withPackages (ps: with ps;
              [
                gunicorn markdown
                # https://github.com/jonashaag/klaus/issues/309
                (klaus.overrideAttrs (o:
                  {
                    patches = (o.patches or [ ]) ++
                    [
                      ../resource/klaus/patch/0001-retrieve-only-HEAD-for-last-updated-of-repo.patch
                    ];
                  })
                )
              ]);
          in
            {
              enable = true;
              description = "klaus git viewer";
              path = [ pkgs.git ];
              environment =
              {
                KLAUS_SITE_NAME = "${config.networking.fqdn} by Katze";
                KLAUS_REPOS_ROOT = "/var/lib/gitolite/repositories/public";
                KLAUS_USE_SMARTHTTP = "true";
              };
              serviceConfig =
              {
                Type = "simple";
                ExecStart = "${klausGunicorn}/bin/gunicorn --timeout 120 klaus.contrib.wsgi_autoreload";
                User = "git";
                Group = "git";
              };
              wantedBy = [ "multi-user.target" ];
            };
      }
      //
      lib.pipe config.benaryorg.git.mirror
      [
        builtins.attrValues
        (builtins.map (config:
        {
          name = "benaryorg-git-mirror-${config.name}";
          value =
          {
            description = "repository mirror for `${config.name}`";
            after = [ "network-online.target" ];
            serviceConfig =
            {
              Type = "oneshot";
              Nice = 5;
              IOSchedulingClass = "idle";
              User = "git";
              Group = "git";
            };
            script =
            ''
              if
                ! test -e /var/lib/gitolite/repositories/public/${config.name}.git
              then
                ${pkgs.git}/bin/git clone --mirror ${config.url} /var/lib/gitolite/repositories/public/${config.name}.git
                ${pkgs.git}/bin/git --git-dir /var/lib/gitolite/repositories/public/${config.name}.git gc
              else
                ${pkgs.git}/bin/git --git-dir /var/lib/gitolite/repositories/public/${config.name}.git remote update --prune
              fi
            '';
          };
        }))
        builtins.listToAttrs
      ];
    systemd.timers = lib.pipe config.benaryorg.git.mirror
    [
      builtins.attrValues
      (builtins.map (config:
      {
        name = "benaryorg-git-mirror-${config.name}";
        value =
        {
          description = "repository mirror for `${config.name}`";
          wantedBy = [ "timers.target" ];
          timerConfig =
          {
            OnCalendar = config.interval;
            Persistent = true;
          };
        };
      }))
      builtins.listToAttrs
    ];
  };
}
