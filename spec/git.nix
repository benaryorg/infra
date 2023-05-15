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
              description = "Interval of update in seconds.";
              default = 3600;
              type = types.int;
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
          push( @{$RC{ENABLE}}, 'symbolic-ref' );
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
            locations."~ \"^/[a-zA-Z0-9._-]+/(git-(receive|upload)-pack|HEAD|info/refs|objects/(info/(http-)?alternates|packs)|[0-9a-f]{2}/[0-9a-f]{38}|pack/pack-[0-9a-f]{40}\\.(pack|idx))$\"" =
            {
              fastcgiParams = 
              {
                SCRIPT_FILENAME = "${pkgs.git}/bin/git-http-backend";
                GIT_PROJECT_ROOT = "/var/lib/gitolite/repositories/public";
                GIT_HTTP_EXPORT_ALL = "";
                PATH_INFO = "$fastcgi_script_name";
              };
              extraConfig =
              ''
                fastcgi_read_timeout 1800;
                fastcgi_pass unix:/run/fcgiwrap.sock;
              '';
            };
          };
        };
      };
      fcgiwrap =
      {
        enable = true;
        group = "git";
        # important; security vulns in git will have major impact here
        # anonymous write here is only soft-disabled by upstream sanity checks against the repo config
        # https://git-scm.com/docs/git-daemon#Documentation/git-daemon.txt-receive-pack
        user = "git";
        preforkProcesses = 8;
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
                      ../resource/klaus/patch/5f0a7cb7d4186bb9729d73a2864f0e830431f327.patch
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
                KLAUS_USE_SMARTHTTP = "false";
              };
              serviceConfig =
              {
                Type = "simple";
                ExecStart = "${klausGunicorn}/bin/gunicorn --threads 8 --timeout 120 klaus.contrib.wsgi_autoreload";
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
            OnUnitActiveSec = config.interval;
            Persistent = true;
          };
        };
      }))
      builtins.listToAttrs
    ];
  };
}
