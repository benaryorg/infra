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
      # apparently nix requires this now to build properly in restricted mode, and it does so with all three schemas
      allowed-uris = lib.mkOrder 1000 (builtins.map (schema: "${schema}://git.shell.bsocat.net/") [ "https" "git+https" "tarball+https" ]);
    };
    nix.gc.automatic = true;
    nix.gc.options = "--delete-older-than 16d";
    nixpkgs.flake.source = pkgs.path;
    environment.etc.nixpkgs.source = config.nixpkgs.flake.source;
    systemd.services.nix-daemon.environment.TMPDIR = "/nix/tmp";
    systemd.tmpfiles.rules = [ "v '/nix/tmp' 0755 root root - -" ];
  };
}
