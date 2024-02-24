{ modulesPath, ... }:
{
  benaryorg.deployment.fake = true;

  imports =
  [
    (modulesPath + "/virtualisation/lxc-container.nix")
  ];

  benaryorg.build.role = "client-light";
  benaryorg.build.tags = [ "cloud.bsocat.net" ];
  benaryorg.flake.autoupgrade = false;

  # the channel is handled by benaryorg/nix already
  system.installer.channel.enable = false;
}
