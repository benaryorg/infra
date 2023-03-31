{ config, pkgs, lib, options, ... }:
with lib;
{
  options =
  {
    benaryorg.flake =
    {
      enable = mkOption
      {
        default = true;
        description = "Whether to enable flake deployment.";
        type = types.bool;
      };
      autoupgrade = mkOption
      {
        default = true;
        description = "Whether enable regular automatic upgrades.";
        type = types.bool;
      };
      url = mkOption
      {
        default = "git+https://shell.cloud.bsocat.net/infra";
        description = "The flake URl to deploy.";
        type = types.str;
      };
    };
  };

  config = mkIf config.benaryorg.flake.enable
  {
    system.autoUpgrade = mkIf config.benaryorg.flake.autoupgrade
    {
      enable = true;
      flake = "/etc/nixos";
      flags = [ "--update-input" "benaryorg" "--update-input" "nixpkgs" "--refresh" "--commit-lock-file" ];
    };
    environment.etc."nixos/flake.nix" =
    {
      mode = "0444";
      text =
      ''
        {
          inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
          inputs.benaryorg.url = "${config.benaryorg.flake.url}";
          inputs.benaryorg.inputs.nixpkgs.follows = "nixpkgs";

          outputs = { benaryorg, ... }:
          {
            inherit (benaryorg) nixosConfigurations;
          };
        }
      '';
    };
  };
}
