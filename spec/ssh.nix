{ config, pkgs, lib, options, ... }:
with lib;
{
  options =
  {
    benaryorg.ssh =
    {
      enable = mkOption
      {
        default = true;
        description = "Whether to enable OpenSSH server.";
        type = types.bool;
      };
      x11 = mkOption
      {
        default = false;
        description = "Whether to enable X11 forwarding.";
        type = types.bool;
      };
    };
  };

  config =
  {
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
