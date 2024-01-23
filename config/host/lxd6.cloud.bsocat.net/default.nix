{ name, nodes, pkgs, lib, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIa1t6BignThNJcZzAkhY55aWXPuzAU1KZW+O+C/r4dN";

  age.secrets.lxdLegoSecret.file = ./secret/lego/hedns/lxd6.cloud.bsocat.net.age;
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
  benaryorg.net.host.ipv4 = "37.187.145.124/24";
  benaryorg.net.host.ipv4Gateway = "37.187.145.254";
  benaryorg.net.host.ipv6 = "2001:41d0:a:517c::1/56";
  benaryorg.net.host.ipv6Gateway = "2001:41d0:a:51ff:ff:ff:ff:ff";
  benaryorg.hardware.ovh =
  {
    device =
    {
      sda = { uuid = "6fbaef44-b179-43f3-88ca-8e5f1bc3c3f0"; keyuuid = "5a2aaeea-6981-6b4d-91c4-61dcaa8cb12e"; };
      sdb = { uuid = "fa938535-0599-458b-9ff8-55f7f41eff6f"; keyuuid = "a5f0c623-ee37-5e4e-a78d-a4271a0c4b04"; };
    };
    fs =
    {
      root = "ea9ea296-44d8-43f2-9ceb-1c765b1b1b7d";
      boot = "eaa28e6d-63df-46c6-9a13-652b6c0a5ce4";
    };
  };

  system.stateVersion = "23.11";
}
