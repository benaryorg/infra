{ config, pkgs, lib, options, ... }:
{
  config =
  {
    nix.settings =
    {
      experimental-features = [ "nix-command" "flakes" ];
      keep-outputs = true;
      builders-use-substitutes = true;
      fallback = true;
      allowed-uris = lib.mkOrder 1000
      [
        "https://git.shell.bsocat.net/" # regular git mirror
      ];
    };
    nix.gc.automatic = true;
    nix.gc.options = "--delete-older-than 16d";
    nixpkgs.flake.source = pkgs.path;
    environment.etc.nixpkgs.source = config.nixpkgs.flake.source;
    systemd.services.nix-daemon.environment.TMPDIR = "/nix/tmp";
    systemd.tmpfiles.rules = [ "v '/nix/tmp' 0755 root root - -" ];
  };
}
