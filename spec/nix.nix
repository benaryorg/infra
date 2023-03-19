{ config, pkgs, lib, options, ... }:
with lib;
{
  config =
  {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.gc.automatic = true;
  };
}
