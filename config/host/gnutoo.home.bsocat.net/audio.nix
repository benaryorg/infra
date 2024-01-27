{ pkgs, lib, config, ... }:
{
  users.users.benaryorg.packages = with pkgs; [ pipewire wireplumber pulsemixer alsa-utils ];

  sound.enable = true;
  security.rtkit.enable = true;
  services.stunnel =
  {
    enable = true;
    user = "benaryorg";
    servers =
    {
      netaudio =
      {
        accept = ":::9998";
        # FIXME? maybe make this more stable?
        connect = "/run/user/1000/pulse/native";
        cert = "/run/credentials/stunnel.service/cert.pem";
        key = "/run/credentials/stunnel.service/key.pem";
        CAFile = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        checkHost = "mir.home.bsocat.net";
        sslVersion = "TLSv1.3";
        verifyChain = true;
      };
    };
  };
  security.acme.certs.${config.networking.fqdn}.listenHTTP = ":80";
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
    };
  };
  services.pipewire =
  {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
    socketActivation = false;
  };
  systemd.user.services.pipewire.path = lib.mkAfter [ pkgs.pipewire pkgs.wireplumber ];
  systemd.user.services.pipewire.environment.LADSPA_PATH = "${pkgs.rnnoise-plugin}/lib/ladspa";
  systemd.user.services.pipewire.environment.XDG_CONFIG_HOME = pkgs.copyPathToStore ./file/pipewire-config-home;
  systemd.user.services.pipewire-pulse.enable = lib.mkForce false;
  systemd.user.services.wireplumber.enable = lib.mkForce false;
}
