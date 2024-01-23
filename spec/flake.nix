{ config, pkgs, lib, options, ... }:
{
  options =
  {
    benaryorg.flake =
    {
      enable = lib.mkOption
      {
        default = true;
        description = "Whether to enable flake deployment.";
        type = lib.types.bool;
      };
      autoupgrade = lib.mkOption
      {
        default = true;
        description = "Whether enable regular automatic upgrades.";
        type = lib.types.bool;
      };
      url = lib.mkOption
      {
        default = "git+https://git.shell.bsocat.net/infra?ref=main";
        description = "The flake URl to deploy.";
        type = lib.types.str;
      };
      nixpkgs = lib.mkOption
      {
        default = "tarball+https://git.shell.bsocat.net/nixpkgs/snapshot/nixpkgs-nixos-23.11.tar.gz";
        description = "The nixpkgs distribution to use.";
        type = lib.types.str;
      };
    };
  };

  config = lib.mkIf config.benaryorg.flake.enable
  {
    system.autoUpgrade = lib.mkIf config.benaryorg.flake.autoupgrade
    {
      enable = true;
      dates = "daily";
      flake = "/etc/nixos";
      flags = [ "--update-input" "benaryorg" "--update-input" "nixpkgs" "--refresh" "--commit-lock-file" "--recreate-lock-file" ];
    };
    systemd.timers.nixos-upgrade = lib.mkIf config.benaryorg.flake.autoupgrade
    {
      timerConfig =
      {
        OnBootSec = "1h";
        RandomizedDelaySec = lib.mkForce "24h";
      };
    };
    systemd.services.nixos-upgrade = lib.mkIf config.benaryorg.flake.autoupgrade
    {
      onFailure = [ "default.target" ];
      unitConfig.OnFailureJobMode = "isolate";
    };
    environment.etc =
    {
      "nixos/flake.nix" =
      {
        mode = "0444";
        text =
        ''
          {
            inputs.benaryorg.url = "${config.benaryorg.flake.url}";
            inputs.nixpkgs.url = "${config.benaryorg.flake.nixpkgs}";
            inputs.benaryorg.inputs.nixpkgs.follows = "nixpkgs";

            outputs = { benaryorg, ... }:
            {
              inherit (benaryorg) nixosConfigurations;
            };
          }
        '';
      };
    };
  };
}
