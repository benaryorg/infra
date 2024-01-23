{ name, nodes, pkgs, lib, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKqIBwvc1Pf6GbuVs8fo1UFGJLomb47VJO01ZzFv+BSK";

  benaryorg.user.ssh.keys = [ nodes."gnutoo.home.bsocat.net".config.benaryorg.ssh.userkey.benaryorg ];
  benaryorg.ssh.x11 = true;
  hardware.opengl.enable = true;
  benaryorg.prometheus.client.enable = true;
  security.acme.certs.${config.networking.fqdn}.listenHTTP = ":80";
  systemd.network.networks."40-ipv4".enable = lib.mkForce false;

  users.users.benaryorg.packages = with pkgs;
  [
    alacritty
    appimage-run
    dumb-init
    xpra
    xterm
  ];

  system.stateVersion = "23.11";
}
