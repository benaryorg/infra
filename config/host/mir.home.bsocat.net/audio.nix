{ pkgs, lib, config, ... }:
{
  users.users.benaryorg.packages = with pkgs; [ pulsemixer alsa-utils ];

  services.stunnel =
  {
    enable = true;
    clients =
    {
      netaudio =
      {
        accept = "::1:9999";
        connect = "gnutoo.home.bsocat.net:9998";
        cert = "/run/credentials/stunnel.service/cert.pem";
        key = "/run/credentials/stunnel.service/key.pem";
        CAFile = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        checkHost = "gnutoo.home.bsocat.net";
        sslVersion = "TLSv1.3";
        verifyChain = true;
      };
    };
  };
  systemd.services =
  {
    stunnel =
    {
      wants = [ "acme-finished-${config.networking.fqdn}.target" ];
      after = [ "acme-finished-${config.networking.fqdn}.target" ];
      serviceConfig.LoadCredential =
      [
        "cert.pem:/var/lib/acme/${config.networking.fqdn}/cert.pem"
        "key.pem:/var/lib/acme/${config.networking.fqdn}/key.pem"
      ];
      serviceConfig.CPUSchedulingPolicy = "rr";
      serviceConfig.CPUSchedulingPriority = 10;
      serviceConfig.Nice = -11;
    };
  };

  hardware.pulseaudio.enable = true;
  systemd.user.services.pulseaudio.serviceConfig =
  {
    ExecStart = lib.mkForce [ "" "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd ::1:9999" ];
  };
}
