{ name, config, pkgs, lib, options, ... }:
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
          $RC{SITE_INFO} = "${name} by Katze";
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
        virtualHosts =
        {
          "${name}" =
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
          klausGunicorn = pkgs.python3.withPackages (ps: with ps; [gunicorn klaus markdown]);
        in
          {
            enable = true;
            description = "klaus git viewer";
            path = [ pkgs.git ];
            environment =
            {
              KLAUS_SITE_NAME = "${name} by Katze";
              KLAUS_REPOS_ROOT = "/var/lib/gitolite/repositories/public";
              KLAUS_USE_SMARTHTTP = "true";
            };
            unitConfig =
            {
              Type = "simple";
            };
            serviceConfig =
            {
              ExecStart = "${klausGunicorn}/bin/gunicorn klaus.contrib.wsgi_autoreload";
              User = "git";
              Group = "git";
            };
            wantedBy = [ "multi-user.target" ];
          };
    };
    security.acme =
    {
      acceptTerms = true;
      defaults.email = "letsencrypt@benary.org";
    };
  };
}
