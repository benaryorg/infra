{ name, nodes, pkgs, lib, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBNnok7mR9DK1pMAIlae5TG1fMzTtPOQGnNfSNtRy/5m";

  age.secrets.lxdLegoSecret.file = ./secret/lego/hedns/lxd4.cloud.bsocat.net.age;
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
  benaryorg.net.host.primaryInterface = "enp1s0";
  benaryorg.net.host.ipv4 = "37.187.92.26/24";
  benaryorg.net.host.ipv4Gateway = "37.187.92.254";
  benaryorg.net.host.ipv6 = "2001:41d0:a:341a::1/56";
  benaryorg.net.host.ipv6Gateway = "2001:41d0:a:34ff:ff:ff:ff:ff";
  benaryorg.hardware.ovh =
  {
    device =
    {
      sda = { uuid = "c584315c-0738-4918-864f-18c7cbc756c0"; keyuuid = "5ba91813-4643-244c-9774-d4766bb7a805"; };
      sdb = { uuid = "706c9c32-741b-4dcb-8c5b-b22ad037f086"; keyuuid = "e3c763f4-5d28-4849-82d8-506f341e3a66"; };
    };
    fs =
    {
      root = "306a9a07-947a-4e4d-be61-5b2f15410831";
      boot = "bdee9321-64ae-4bf6-92b7-a76377b7f9f6";
    };
  };

  system.stateVersion = "23.11";
}
