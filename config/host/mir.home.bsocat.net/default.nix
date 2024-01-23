{ name, nodes, pkgs, lib, config, ... }:
{
  benaryorg.deployment.fake = true;

  benaryorg.ssh.userkey.benaryorg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKubEmPiQTJCpFuXhubW3SDlxoBXK+sFhcHsUH6kz32p";

  benaryorg.build.role = "none";
  benaryorg.prometheus.client.enable = true;
  benaryorg.prometheus.client.exporters.smokeping.enable = false;
  benaryorg.prometheus.client.exporters.systemd.enable = false;
  benaryorg.prometheus.client.mocks.ceph =
  {
    port = 19283;
  };
}
