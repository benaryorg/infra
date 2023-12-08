{ config, lib, ... }:
with lib;
{
  options =
  {
    benaryorg.deployment =
    {
      default = mkOption
      {
        default = !config.benaryorg.deployment.fake;
        description = "Whether to add the host to the @default colmena deployment.";
        type = types.bool;
      };
      fake = mkOption
      {
        default = false;
        description = "Whether the host is fake. Fake hosts are not built and tested, they are merely used for relationships in other modules (such as monitoring).";
        type = types.bool;
      };
      tags = mkOption
      {
        default = [];
        description = "List of tags to apply to colmena.";
        type = types.listOf types.str;
      };
    };
  };

  config =
  {
    benaryorg.deployment.tags = mkOrder 1000 (optionals config.benaryorg.deployment.default [ "default" ]);
  };
}
