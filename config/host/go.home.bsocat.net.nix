{ name, nodes, pkgs, lib, config, ... }:
{
  benaryorg.deployment.fake = true;

  benaryorg.ssh.userkey.defaultuser = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOwmYJYilHh3ICizwCrBHh8tUGhodC8dv73IUTJp8jP2";

  benaryorg.build.role = "none";
}
