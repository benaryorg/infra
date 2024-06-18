{ nodes, lib, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOngRNLmPolBgNpBPfnCXyVncNaSiErRWF+/lmAhX9u9";

  age.secrets.buildSecret.file = ./secret/build/nixos.home.bsocat.net.age;
  benaryorg.net.type = "manual";
  benaryorg.ssh.x11 = true;
  benaryorg.user.ssh.keys = lib.mkAfter [ nodes."gnutoo.home.bsocat.net".config.benaryorg.ssh.userkey.benaryorg nodes."mir.home.bsocat.net".config.benaryorg.ssh.userkey.benaryorg ];
  benaryorg.prometheus.client.enable = true;

  benaryorg.build =
  {
    role = "server";
    publicKey = "nixos.home.bsocat.net:yiK6zWXrGJRUw2LqhSqr9x1H6jbeLl/nokgJJBVJZ80=";
    privateKeyFile = config.age.secrets.buildSecret.path;
    systems = [ "x86_64-linux" ];
  };

  fileSystems."/nix/tmp" = { fsType = "tmpfs"; options = [ "noatime" "size=8g" ]; };

  networking.nameservers = [ "2a0c:b641:a40:5::" ];

  system.stateVersion = "23.11";
}
