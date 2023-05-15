{ config, pkgs, lib, options, ... }:
with lib;
{
  config =
  {
    nix.settings =
    {
      experimental-features = [ "nix-command" "flakes" ];
      keep-outputs = true;
      builders-use-substitutes = true;
    };
    nix.gc.automatic = true;
    nix.gc.options = "--delete-older-than 16d";
    systemd.services.nix-daemon.environment.TMPDIR = "/nix/tmp";
    system.activationScripts.nix-tmpdir =
    ''
      test -d /nix/tmp || ${pkgs.btrfs-progs}/bin/btrfs subvolume create /nix/tmp || mkdir -p /nix/tmp
    '';
  };
}
