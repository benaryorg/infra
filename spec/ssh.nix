{ config, lib, options, ... }:
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
      userkey = lib.mkOption
      {
        description = lib.mdDoc
        ''
          List user SSH keys.
          This is used to deploy these SSH keys to other nodes by accessing {option}`nodes.<node>.benaryorg.ssh.userkey.<name>`.
          Keys listed here should be those that reside in {file}`/home/<user>/.ssh/*`.
        '';
        default = {};
        example = { benaryorg = "ssh-ed25519 foobar"; };
        type = lib.types.attrsOf lib.types.str;
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
