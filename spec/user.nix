{ config, pkgs, lib, options, ... }:
with lib;
{
  options =
  {
    benaryorg.user =
    {
      ssh =
      {
        enable = mkOption
        {
          default = true;
          description = "Whether to enroll the default SSH user.";
          type = types.bool;
        };
        name = mkOption
        {
          default = "benaryorg";
          description = "Name of the default SSH user.";
          type = types.str;
        };
        keys = mkOption
        {
          default = [];
          description = "List of SSH public keys.";
          type = types.listOf types.str;
        };
      };
    };
  };

  config =
  {
    users.users = mkIf config.benaryorg.user.ssh.enable
    {
      root.hashedPassword = "*";
      ${config.benaryorg.user.ssh.name} =
      {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = config.benaryorg.user.ssh.keys;
      };
    };
  };
}
