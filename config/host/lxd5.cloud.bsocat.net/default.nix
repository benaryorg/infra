{ name, nodes, pkgs, lib, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMaVAQfp0SDxPbCj/3v1daa96z6PgA40EBLOQzQeCMUp";

  age.secrets.lxdLegoSecret.file = ./secret/lego/hedns/lxd5.cloud.bsocat.net.age;
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
  benaryorg.net.host.ipv4 = "192.99.12.118/24";
  benaryorg.net.host.ipv4Gateway = "192.99.12.254";
  benaryorg.net.host.ipv6 = "2607:5300:60:3d76::1/56";
  benaryorg.net.host.ipv6Gateway = "2607:5300:60:3dff:ff:ff:ff:ff";
  benaryorg.hardware.ovh =
  {
    device =
    {
      sda = { uuid = "64b37fa9-981c-42b7-b67e-c0d283270306"; keyuuid = "5283db23-c3b3-2d48-b633-faff893c99f1"; };
    };
    fs =
    {
      root = "2919e656-e9e6-4fa5-8699-f2a0b7677a59";
      boot = "b51fb8bd-b5b6-4b94-8e5e-51c90faa2b0d";
    };
  };

  system.stateVersion = "23.11";
}
