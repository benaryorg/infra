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
    systemd.tmpfiles.rules = [ "v '/nix/tmp' 0755 root root - -" ];
  };
}
