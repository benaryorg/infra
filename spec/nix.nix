{ config, pkgs, lib, options, ... }:
with lib;
{
  config =
  {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.gc.automatic = true;
    systemd.services.nix-daemon.environment.TMPDIR = "/nix/tmp";
    system.activationScripts.nix-tmpdir =
    ''
      btrfs subvolume create /nix/tmp || mkdir -p /nix/tmp
    '';
  };
}
