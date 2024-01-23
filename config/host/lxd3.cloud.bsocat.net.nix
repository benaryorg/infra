{ name, nodes, pkgs, lib, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMWOCWu2yJ2MK7LZSrLYttRZhat6stqTjG/WQaYSEl/3";

  age.secrets.lxdLegoSecret.file = ../../secret/lego/hedns/lxd3.cloud.bsocat.net.age;
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
  benaryorg.net.host.ipv4 = "198.100.145.227/24";
  benaryorg.net.host.ipv4Gateway = "198.100.145.254";
  benaryorg.net.host.ipv6 = "2607:5300:60:8e3::1/56";
  benaryorg.net.host.ipv6Gateway = "2607:5300:60:8ff:ff:ff:ff:ff";
  benaryorg.hardware.ovh =
  {
    device =
    {
      sda = { uuid = "ba52e296-4b0b-4d6f-86af-e3c133b59375"; keyuuid = "f6847590-dbb8-4940-9986-bbceedb58b46"; };
    };
    fs =
    {
      root = "694e3cbd-20ee-4b39-a768-47dcf7df1373";
      boot = "62c57898-8398-49ce-ad3b-198ab2299b46";
    };
  };

  system.stateVersion = "23.11";
}
