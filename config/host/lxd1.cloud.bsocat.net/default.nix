{ name, nodes, pkgs, lib, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMQN8n7AM1npiKBQiyUIg1PzT06umWFcfFFXKV5XSS8R";

  age.secrets.lxdLegoSecret.file = ./secret/lego/hedns/lxd1.cloud.bsocat.net.age;
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
  benaryorg.net.host.ipv4 = "94.23.38.16/24";
  benaryorg.net.host.ipv4Gateway = "94.23.38.254";
  benaryorg.net.host.ipv6 = "2001:41d0:2:2710::1/56";
  benaryorg.net.host.ipv6Gateway = "2001:41d0:2:27ff:ff:ff:ff:ff";
  benaryorg.hardware.ovh =
  {
    device =
    {
      sda = { uuid = "7bf4045c-6a00-4692-9c20-5a7f44dc085c"; keyuuid = "1d772c63-594e-144b-bbb2-18956c84c998"; };
      sdb = { uuid = "a72e9fb2-454c-4ca7-b6c7-a5d1d975832a"; keyuuid = "d497d602-36a8-7549-9127-014241c0a535"; };
    };
    fs =
    {
      root = "daa52a9d-e14d-43b4-befa-a18c6225dd7f";
      boot = "9d48e3b9-ef76-48b8-969a-266cf0b76be1";
    };
  };

  system.stateVersion = "23.11";
}
