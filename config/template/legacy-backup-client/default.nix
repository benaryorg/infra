{ name, nodes, pkgs, lib, config, ... }:
{
  benaryorg.deployment.fake = true;

  benaryorg.build.role = "none";
  benaryorg.backup.role = "client";
  benaryorg.backup.client.directories = [ "/" ];
  benaryorg.backup.client.excludes =
  [
    "/dev"
    "/media"
    "/mnt"
    "/proc"
    "/run"
    "/nix"
    "/sys"
    "/tmp"
    "/var/cache"
    "/var/db/repos/gentoo"
    "/var/tmp"
  ];
}
