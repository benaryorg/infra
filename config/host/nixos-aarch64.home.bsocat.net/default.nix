{ nodes, lib, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICST4L1PUhwaRr0Elq618UqWn/oNytDblkmEG3UDao3b";

  age.secrets.buildSecret.file = ./secret/build/nixos-aarch64.home.bsocat.net.age;
  benaryorg.net.type = "manual";
  benaryorg.ssh.x11 = true;
  benaryorg.user.ssh.keys = lib.mkAfter [ nodes."gnutoo.home.bsocat.net".config.benaryorg.ssh.userkey.benaryorg ];
  benaryorg.prometheus.client.enable = true;

  benaryorg.build =
  {
    role = "server";
    publicKey = "nixos-aarch64.home.bsocat.net:pV77z/+Ovmn/fK5YtV6FANXG+q4x926/wFhxqet/rWU=";
    privateKeyFile = config.age.secrets.buildSecret.path;
    systems = [ "aarch64-linux" ];
    tags = lib.mkAfter [ "aarch64-linux" ];
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  nix.settings.extra-platforms = [ "aarch64-linux" ];

  fileSystems."/nix/tmp" = { fsType = "tmpfs"; options = [ "noatime" "size=8g" ]; };

  networking.nameservers = [ "2a0c:b641:a40:5::" ];

  system.stateVersion = "23.11";
}
