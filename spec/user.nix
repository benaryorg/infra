{ config, pkgs, lib, options, ... }:
{
  options =
  {
    benaryorg.user =
    {
      ssh =
      {
        enable = lib.mkOption
        {
          default = true;
          description = "Whether to enroll the default SSH user.";
          type = lib.types.bool;
        };
        name = lib.mkOption
        {
          default = "benaryorg";
          description = "Name of the default SSH user.";
          type = lib.types.str;
        };
        keys = lib.mkOption
        {
          default = [];
          description = "List of SSH public keys.";
          type = lib.types.listOf lib.types.str;
        };
      };
    };
  };

  config =
  {
    users.users = lib.mkIf config.benaryorg.user.ssh.enable
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
