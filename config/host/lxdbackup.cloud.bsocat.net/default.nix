{ nodes, lib, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPZHNdrsaOQI7+C66BidPG9qtvIzuu2rwLsMCHD4fMVt";

  benaryorg.user.ssh.keys = lib.mkAfter [ nodes."gnutoo.home.bsocat.net".config.benaryorg.ssh.userkey.benaryorg ];
  benaryorg.backup.role = "server";
  benaryorg.prometheus.client.enable = true;

  services.beesd.filesystems =
  {
    root =
    {
      spec = "/";
      hashTableSizeMB = 2048;
      verbosity = "warning";
    };
  };

  benaryorg.hardware.vendor = "ovh";
  benaryorg.net.host.primaryInterface = "eno1";
  benaryorg.net.host.ipv4 = "142.4.213.97/24";
  benaryorg.net.host.ipv4Gateway = "142.4.213.254";
  benaryorg.net.host.ipv6 = "2607:5300:60:1261::1/56";
  benaryorg.net.host.ipv6Gateway = "2607:5300:60:12ff:ff:ff:ff:ff";
  benaryorg.hardware.ovh =
  {
    device =
    {
      sda = { uuid = "d4d4f9ac-c755-43a3-8ae6-abf87bc40d86"; keyuuid = "018dcae6-ee16-49ad-916b-2e18e8216836"; };
    };
    fs =
    {
      root = "07ac51c9-6f38-47d0-8f1a-86feab30f021";
      boot = "4646bf72-57fd-40ea-ba28-7166edb1178b";
    };
  };

  security.acme.certs.${config.networking.fqdn}.listenHTTP = ":80";

  system.stateVersion = "24.05";
}

