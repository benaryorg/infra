{ name, nodes, pkgs, lib, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILhgl6pXnjK5ZxzFduRmZkSbx5bsF8Tito0M2n8A+2HZ";
  benaryorg.ssh.userkey.benaryorg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrKgj+479k+nZjVKAeVnh0clxh6MUuEmY0BTtaNMDi5";

  deployment.allowLocalDeployment = true;
  benaryorg.flake.autoupgrade = false;
  benaryorg.build.role = "none";

  age.secrets.lxdLegoSecret.file = ./secret/lego/hedns/shell.cloud.bsocat.net.age;
  benaryorg.base.sudo.needsPassword = true;
  benaryorg.deployment.default = false;
  benaryorg.prometheus.client.enable = true;

  benaryorg.hardware.vendor = "ovh";
  benaryorg.ssh.x11 = true;
  benaryorg.user.ssh.keys = lib.pipe nodes
  [
    builtins.attrValues
    (builtins.map (node: node.config.benaryorg.ssh.userkey))
    (builtins.map builtins.attrValues)
    lib.flatten
  ];
  benaryorg.lxd.enable = true;
  benaryorg.lxd.cluster = "shell.bsocat.net";
  benaryorg.lxd.allowedUsers = [];
  benaryorg.lxd.legoConfig =
  {
    dnsProvider = "hurricane";
    credentialsFile = config.age.secrets.lxdLegoSecret.path;
    webroot = null;
  };

  zramSwap.enable = true;
  services.openssh.settings.MaxStartups = "50";
  # FIXME: shouldn't be required, potentially needs migration of the git repos over to a container
  users.users.nginx.extraGroups = [ "lxddns" ];

  services.nginx =
  {
    enable = true;
    recommendedTlsSettings = true;
    virtualHosts =
    {
      ${config.networking.fqdn} =
      {
        forceSSL = true;
        enableACME = true;
        locations."/" = { return = "302 \"https://git.shell.bsocat.net\""; };
      };
    };
  };

  benaryorg.net.host.primaryInterface = "enp1s0";
  benaryorg.net.host.ipv4 = "213.32.7.146/24";
  benaryorg.net.host.ipv4Gateway = "213.32.7.254";
  benaryorg.net.host.ipv6 = "2001:41d0:303:192::1/56";
  benaryorg.net.host.ipv6Gateway = "2001:41d0:303:1ff:ff:ff:ff:ff";
  benaryorg.hardware.ovh =
  {
    device =
    {
      sda = { uuid = "7d05e9e8-fcd5-462f-be4f-ac6896092a15"; keyuuid = "f85d4432-b7fe-214c-a105-654a8d99d4ea"; };
    };
    fs =
    {
      root = "897816a8-8ff3-494d-9579-55d7e766616c";
      boot = "49e52b5d-3cbc-4318-9fd3-e362dac54dde";
    };
  };

  system.stateVersion = "23.11";
}
