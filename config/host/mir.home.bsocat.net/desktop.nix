{ config, ... }:
{
  benaryorg.desktop.enable = true;

  benaryorg.home-manager.perUserSettings.benaryorg.benaryorg.desktop.extraInitCommands =
  [
    "xrandr --output DP-0 --primary --mode 2560x1440 --rate 144 --output DP-2 --off || true"
  ];

  nixpkgs.config.allowUnfree = true;
  hardware.nvidia =
  {
    open = true;
    nvidiaSettings = false;
    modesetting.enable = false;
    powerManagement.enable = false;
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.xrandrHeads =
  [
    {
      output = "DP-0";
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
