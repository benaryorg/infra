{ config, pkgs, lib, options, ... }:
{
  options =
  {
    benaryorg.ssh =
    {
      enable = lib.mkOption
      {
        default = true;
        description = "Whether to enable OpenSSH server.";
        type = lib.types.bool;
      };
      x11 = lib.mkOption
      {
        default = false;
        description = "Whether to enable X11 forwarding.";
        type = lib.types.bool;
      };
      hostkey = lib.mkOption
      {
        description = "SSH host key of the current host.";
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
    };
  };

  config =
  {
    warnings =
      lib.optional (!config.benaryorg.deployment.fake && builtins.isNull config.benaryorg.ssh.hostkey)
        "non-fake hosts require a hostkey";

    services.openssh =
    {
      enable = config.benaryorg.ssh.enable;
      startWhenNeeded = false;
      settings =
      {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        X11Forwarding = config.benaryorg.ssh.x11;
      };
    };
  };
}
