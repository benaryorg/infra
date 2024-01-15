{ config, pkgs, lib, options, ... }:
{
  options =
  {
    benaryorg.acme =
    {
      enable = lib.mkOption
      {
        default = true;
        description = lib.mdDoc "Whether to enable acme defaults.";
        type = lib.types.bool;
      };
    };
  };

  config = 
    let
      cfg = config.benaryorg.acme;
      commonOptions = [ "--preferred-chain" "ISRG Root X1" ];
    in
      lib.mkIf cfg.enable
      {
        security.acme.defaults =
        {
          extraLegoRunFlags = lib.mkOrder 1000 commonOptions;
          extraLegoRenewFlags = lib.mkOrder 1000 commonOptions;
        };
      };
}
