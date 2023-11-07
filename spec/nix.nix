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
    environment.etc.nixpkgs.source = pkgs.path;
    nix.registry.nixpkgs = { exact = true; from = { type = "indirect"; id = "nixpkgs"; }; to = { path = pkgs.path; type = "path"; }; };
    nix.nixPath = [ "nixpkgs=flake:nixpkgs" ];
    systemd.services.nix-daemon.environment.TMPDIR = "/nix/tmp";
    systemd.tmpfiles.rules = [ "v '/nix/tmp' 0755 root root - -" ];
  };
}
