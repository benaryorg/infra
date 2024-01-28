{ pkgs, lib, config, ... }:
{
  benaryorg.desktop.enable = true;

  benaryorg.home-manager.perUserSettings.benaryorg.benaryorg.desktop.extraInitCommands = [ "xrandr --output DP-3 --primary --mode 2560x1440 --rate 144 --pos 0x0 --output DP-1 --dpi 96 --off --output DP-0 --off || true" ];

  nixpkgs.config.allowUnfree = true;
  hardware.nvidia.open = false;
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.xrandrHeads =
  [
    {
      output = "DP-3";
      primary = true;
      monitorConfig =
      ''
        DisplaySize 600 340
        Option "DPMS" "false"
        Option "PreferredMode" "2560x1440"
      '';
    }
  ];
}
