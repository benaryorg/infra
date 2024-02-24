{ name, pkgs, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA0ia1VnkJ5lVZ2Nsk7tv+1FPFn9P1JrNRdGRYCf1eNY";

  age.secrets.grafanaUser = { file = ./secret/service/grafana/prometheus.lxd.bsocat.net/admin_user.age; owner = "grafana"; mode = "0400"; };
  age.secrets.grafanaPass = { file = ./secret/service/grafana/prometheus.lxd.bsocat.net/admin_pass.age; owner = "grafana"; mode = "0400"; };
  age.secrets.grafanaSecret = { file = ./secret/service/grafana/prometheus.lxd.bsocat.net/secret.age; owner = "grafana"; mode = "0400"; };
  age.secrets.xmppAlerting = { file = ./secret/service/xmpp/xmpp.lxd.bsocat.net/user/benary.org/monitoring.age; };

  benaryorg.backup.client.directories =
  [
    "/var/lib/${config.services.prometheus.stateDir}"
    config.services.grafana.dataDir
  ];

  benaryorg.prometheus.server.enable = true;
  benaryorg.prometheus.client.enable = true;
  services =
  {
    prometheus =
    {
      retentionTime = "360d";
      xmpp-alerts =
      {
        enable = true;
        settings =
        {
          jid = "monitoring@benary.org";
          password_command = "cat \"\${CREDENTIALS_DIRECTORY}/password\"";
          to_jid = "binary@benary.org";
          listen_address = "::1";
          listen_port = 9199;
          text_template =
          ''
            *{{ status.upper() }}* ( `{{ endsAt if status.upper() == "RESOLVED" else startsAt }}` ): _{{ labels.host or labels.instance }}_ ({{ labels.alertname }}): {{ annotations.description or annotations.summary }}
            {{ generatorURL }}
          '';
        };
      };
    };
    grafana =
    {
      enable = true;
      settings =
      {
        database.wal = true;
        security =
        {
          admin_user = "$__file{/run/agenix/grafanaUser}";
          admin_password = "$__file{/run/agenix/grafanaPass}";
          secret_key = "$__file{/run/agenix/grafanaSecret}";
        };
        server =
        {
          http_addr = "127.0.0.1";
          http_port = 3000;
          domain = config.networking.fqdn;
          root_url = "https://${config.networking.fqdn}/";
        };
        analytics.reporting_enabled = false;
        feature_toggles.publicDashboards = true;
      };
      declarativePlugins = with pkgs.grafanaPlugins; [ grafana-piechart-panel ];
      provision =
      {
        enable = true;
        datasources.settings =
        {
          datasources =
          [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://localhost:9090";
              isDefault = true;
              jsonData =
              {
                prometheusType = "Prometheus";
              };
            }
          ];
        };
      };
    };
    nginx =
    {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts.${config.networking.fqdn} =
      {
        enableACME = true;
        forceSSL = true;
        locations."/" =
        {
          proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}/";
          proxyWebsockets = true;
        };
      };
    };
  };
  systemd.services.prometheus-xmpp-alerts.serviceConfig.LoadCredential = [ "password:${config.age.secrets.xmppAlerting.path}" ];

  system.stateVersion = "23.11";
}
