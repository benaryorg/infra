{ name, nodes, pkgs, lib, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPOwEKWHIPHTxmG2IbB/D0S6AJejI3FfQvZJqOSmnKGi";
  benaryorg.ssh.userkey.benaryorg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPp1WESxGNUYOwx3J9W+s0Z7ZqwKx3Jp825tKxE3I8EG";

  nixpkgs.system = "aarch64-linux";

  benaryorg.deployment.fake = true;
  benaryorg.build.tags = [ "aarch64-linux" ];
  benaryorg.build.role = "client";
}
