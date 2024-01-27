{ name, nodes, pkgs, lib, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIs11y4uzabLAmdqd5Zz7owITCiNwx9Z2q5encfwz/kA";

  age.secrets.buildSecret.file = ./secret/build/nixos-builder.shell.bsocat.net.age;

  benaryorg.prometheus.client.enable = true;
  benaryorg.build =
  {
    role = "server";
    tags = [ "shell.bsocat.net" "cloud.bsocat.net" "lxd.bsocat.net" ];
    publicKey = "nixos-builder.cloud.bsocat.net:i0hLFuNDkp781rdD1nmikT7vsf90Nluo13AL1QE6TSc=";
    privateKeyFile = config.age.secrets.buildSecret.path;
  };

  services.nginx.virtualHosts.${config.networking.fqdn}.locations."~ ^/hydra([^\\r\\n]*)$".return = "302 \"https://hydra.shell.bsocat.net$1\"";
  systemd.slices.build =
  {
    enable = true;
    description = "Slice for all services doing build jobs or similar.";
    sliceConfig.MemoryHigh = "24G";
    sliceConfig.MemoryMax = "25G";
  };
  systemd.services =
  {
    nix-daemon = { serviceConfig.Slice = "build.slice"; };
  };

  system.stateVersion = "23.11";
}
