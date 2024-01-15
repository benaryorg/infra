{ config, lib, ... }:
{
  options =
  {
    benaryorg.deployment =
    {
      default = lib.mkOption
      {
        default = !config.benaryorg.deployment.fake;
        description = "Whether to add the host to the @default colmena deployment.";
        type = lib.types.bool;
      };
      fake = lib.mkOption
      {
        default = false;
        description = "Whether the host is fake. Fake hosts are not built and tested, they are merely used for relationships in other modules (such as monitoring).";
        type = lib.types.bool;
      };
      tags = lib.mkOption
      {
        default = [];
        description = "List of tags to apply to colmena.";
        type = lib.types.listOf lib.types.str;
      };
    };
  };

  config =
  {
    benaryorg.deployment.tags = lib.mkOrder 1000 (lib.optionals config.benaryorg.deployment.default [ "default" ]);
  };
}
