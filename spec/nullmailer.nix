{ config, pkgs, lib, options, ... }:
{
  options.benaryorg.nullmailer =
  {
    enable = lib.mkOption
    {
      default = true;
      description = "Whether to use nullmailer.";
      type = lib.types.bool;
    };
    hostmaster = lib.mkOption
    {
      default = "root@benary.org";
      description = "Hostmaster email address.";
      type = lib.types.str;
    };
    remotes = lib.mkOption
    {
      default =
      [
        # TODO: move to defaults and pull from `nodes`
        "smtp1.lxd.bsocat.net smtp port=25 starttls"
        "smtp2.lxd.bsocat.net smtp port=25 starttls"
      ];
      description = "Remotes to send mail to.";
      type = lib.types.listOf lib.types.str;
    };
  };

  config = lib.mkIf config.benaryorg.nullmailer.enable
  {
    services.nullmailer =
    {
      enable = true;
      config =
      {
        defaultdomain = config.networking.fqdn;
        me = config.networking.fqdn;
        doublebounceto = config.benaryorg.nullmailer.hostmaster;
        remotes = lib.concatStringsSep "\n" config.benaryorg.nullmailer.remotes;
      };
    };
  };
}
