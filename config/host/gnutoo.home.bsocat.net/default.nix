{ pkgs, config, ... }:
{
  imports =
  [
    ./boot.nix
    ./net.nix
    ./btrbk.nix
    ./fs.nix
    ./audio.nix
    ./desktop.nix
    ./ipfs.nix
  ];

  # TODO:
  #  - ipfs module
  #  - bootloader funkiness as module

  config =
  {
    benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA+KZjfYgC2k4TN/npR6iiiH6jNFF1dN2yI912pOLZH8";
    benaryorg.ssh.userkey.benaryorg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAsXZcbbZzIjxvguXzAOM/eds9CZl5cqWJBL+ScgHliC";

    benaryorg.hardware.vendor = "none";
    benaryorg.prometheus.client.enable = true;

    # during development
    benaryorg.flake.autoupgrade = false;

    # do whatever else you wanna do (you *can* use the modules for networking and booting though):

    security.acme.certs.${config.networking.fqdn}.listenHTTP = ":80";

    users.users.benaryorg.initialPassword = "1234";
    users.users.benaryorg.group = "benaryorg";
    users.groups.benaryorg.gid = 1000;

    users.users.benaryorg.packages = with pkgs; [ gnupg vim-full ragenix ];

    zramSwap = { enable = true; memoryPercent = 400; };

    console.keyMap = "neo";

    system.stateVersion = "23.11";
  };
}
