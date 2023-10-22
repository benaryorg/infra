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
    {
      enable = true;
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
        source-filter = "${pkgs.cgit}/lib/cgit/filters/syntax-highlighting.py";
        about-filter = "${pkgs.cgit}/lib/cgit/filters/about-formatting.sh";
      };
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
                ${pkgs.git}/bin/git --git-dir /var/lib/gitolite/repositories/public/${config.name}.git repack -d
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
