{ config, pkgs, lib, options, ... }:
{
  options =
  {
    benaryorg.git =
    {
      enable = lib.mkEnableOption "git server functionality";
      adminkey = lib.mkOption
      {
        description = "Gitolite admin SSH key.";
        type = lib.types.str;
      };
      mirror = lib.mkOption
      {
        description = "List of repositories to mirror.";
        default = {};
        example = { nixpkgs = { url = "https://github.com/NixOS/nixpkgs.git"; }; };
        type = lib.types.attrsOf (lib.types.submodule ({ name, ...}:
        {
          options =
          {
            name = lib.mkOption
            {
              description = "Name of the public repository in gitolite.";
              type = lib.types.str;
              default = name;
            };
            interval = lib.mkOption
            {
              description = "Interval of update in seconds.";
              default = 3600;
              type = lib.types.int;
            };
            url = lib.mkOption
            {
              description = "URl of the repository for initial clone.";
              type = lib.types.str;
            };
            owner = lib.mkOption
            {
              description = "Owning gitolite user of the mirrored repository.";
              type = lib.types.str;
              default = config.benaryorg.user.ssh.name;
              defaultText = lib.literalExpression "config.benaryorg.user.ssh.name";
            };
          };
        }));
      };
    };
  };

  config = lib.mkIf config.benaryorg.git.enable
  {
    services =
    {
      openssh.authorizedKeysInHomedir = true;
      gitolite =
      {
        enable = true;
        adminPubkey = config.benaryorg.git.adminkey;
        extraGitoliteRc =
        ''
          $RC{UMASK} = 0027;
          $RC{SITE_INFO} = "${config.networking.fqdn} by Katze";
          $RC{LOCAL_CODE} = "$rc{GL_ADMIN_BASE}/local";
          push( @{$RC{ENABLE}}, 'D' );
          push( @{$RC{ENABLE}}, 'desc' );
          push( @{$RC{ENABLE}}, 'help' );
          push( @{$RC{ENABLE}}, 'symbolic-ref' );
          push( @{$RC{ENABLE}}, 'repo-specific-hooks' );
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
          };
        };
      };
    };

    services.cgit.${config.networking.fqdn} =
      let
        cgit = pkgs.cgit-pink;
      in
        {
          enable = true;
          package = cgit;
          scanPath = "/var/lib/gitolite/repositories/public";
          settings =
          {
            clone-url = "https://${config.networking.fqdn}/$CGIT_REPO_URL";
            branch-sort = "age";
            root-title = "${config.networking.fqdn} by Katze";
            root-desc = "because self-hosted is better";
            snapshots = "tar.gz";
            readme = ":README.md";
            enable-index-owner = false;
            enable-follow-links = true;
            remove-suffix = true;
            source-filter = "${cgit}/lib/cgit/filters/syntax-highlighting.py";
            about-filter = "${cgit}/lib/cgit/filters/about-formatting.sh";
          };
        };

    services.fcgiwrap =
    {
      user = config.services.gitolite.user;
      group = config.services.gitolite.group;
    };

    systemd.services = lib.pipe config.benaryorg.git.mirror
      [
        builtins.attrValues
        (builtins.map (config:
        {
          name = "benaryorg-git-mirror-${config.name}";
          value =
          {
            description = "repository mirror for `${config.name}`";
            wants = [ "network-online.target" ];
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
              set -e
              if
                ! test -e /var/lib/gitolite/repositories/public/${config.name}.git
              then
                ${pkgs.git}/bin/git clone --mirror ${config.url} /var/lib/gitolite/repositories/public/${config.name}.git
              else
                ${pkgs.git}/bin/git --git-dir /var/lib/gitolite/repositories/public/${config.name}.git config maintenance.auto false
                ${pkgs.git}/bin/git --git-dir /var/lib/gitolite/repositories/public/${config.name}.git remote update --prune
              fi
              ${pkgs.git}/bin/git --git-dir /var/lib/gitolite/repositories/public/${config.name}.git maintenance run --task=gc
              printf "mirror of %s" ${config.url} > /var/lib/gitolite/repositories/public/${config.name}.git/description
              touch /var/lib/gitolite/repositories/public/${config.name}.git/git-daemon-export-ok
              printf "%s" ${config.owner} > /var/lib/gitolite/repositories/public/${config.name}.git/gl-creator
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
            OnUnitInactiveSec = config.interval;
            OnBootSec = config.interval;
            Persistent = true;
          };
        };
      }))
      builtins.listToAttrs
    ];
  };
}
