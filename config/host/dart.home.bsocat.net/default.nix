{ name, nodes, pkgs, lib, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBz6svwHHhGz+/C2FKHCC1XaKEnaHc20fp+YOQTojpzU";
  benaryorg.ssh.userkey.benaryorg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpkNc/B083GREqQrk6sOciWvC4k9uU6J3K33LErICQy";

  nixpkgs.system = "aarch64-linux";

  benaryorg.deployment.fake = true;
  benaryorg.build.tags = [ "aarch64-linux" ];
  benaryorg.build.role = "client";
}
