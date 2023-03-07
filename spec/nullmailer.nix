{ config, pkgs, lib, options, ... }:
with lib;
{
  options.benaryorg.nullmailer =
  {
    enable = mkOption
    {
      default = true;
      description = "Whether to use nullmailer.";
      type = types.bool;
    };
    hostmaster = mkOption
    {
      default = "root@benary.org";
      description = "Hostmaster email address.";
      type = types.str;
    };
    remotes = mkOption
    {
      default =
      [
        # TODO: move to defaults and pull from `nodes`
        "smtp1.lxd.bsocat.net smtp port=25 starttls"
        "smtp2.lxd.bsocat.net smtp port=25 starttls"
      ];
      description = "Remotes to send mail to.";
      type = types.listOf types.str;
    };
  };

  config =
  {
    services.nullmailer =
    {
      enable = config.benaryorg.nullmailer.enable;
      config =
      {
        defaultdomain = config.networking.fqdn;
        me = config.networking.fqdn;
        doublebounceto = config.benaryorg.nullmailer.hostmaster;
        remotes = concatStringsSep "\n" config.benaryorg.nullmailer.remotes;
      };
    };
  };
}
