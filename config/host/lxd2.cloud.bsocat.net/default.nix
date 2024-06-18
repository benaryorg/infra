{ config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIACQK4kpl9p3Y4ZtpqEyvostg7zmnFpb91Z3b+gxDwGQ";

  age.secrets.lxdLegoSecret.file = ./secret/lego/hedns/lxd2.cloud.bsocat.net.age;
  benaryorg.prometheus.client.enable = true;
  benaryorg.hardware.vendor = "ovh";
  benaryorg.lxd.enable = true;
  benaryorg.lxd.cluster = "lxd.bsocat.net";
  benaryorg.lxd.legacySmtpProxy = true;
  benaryorg.lxd.legoConfig =
  {
    dnsProvider = "hurricane";
    credentialsFile = config.age.secrets.lxdLegoSecret.path;
  };
  benaryorg.net.host.primaryInterface = "eno1";
  benaryorg.net.host.ipv4 = "37.187.8.147/24";
  benaryorg.net.host.ipv4Gateway = "37.187.8.254";
  benaryorg.net.host.ipv6 = "2001:41d0:a:893::1/56";
  benaryorg.net.host.ipv6Gateway = "2001:41d0:a:8ff:ff:ff:ff:ff";
  benaryorg.hardware.ovh =
  {
    device =
    {
      sda = { uuid = "d7e0b6a4-b4d2-4a69-a103-2a2299ca72b2"; keyuuid = "e91250a9-a575-9a48-98e3-8d07672d7f21"; };
    };
    fs =
    {
      root = "dd4353e5-fbea-4906-a694-e9a7cb1b4679";
      boot = "f13918cc-9ac3-4c86-a221-87805beaa80d";
    };
  };

  system.stateVersion = "24.05";
}
