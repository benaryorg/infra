{ config, ... }:
{
  boot.supportedFilesystems =
  {
    ext4 = true;
    vfat = true;
    btrfs = true;
  };
  boot.initrd.supportedFilesystems = config.boot.supportedFilesystems;
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  boot.swraid =
  {
    enable = true;
    mdadmConf = "MAILADDR root@benary.org";
  };

  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices =
  {
    keydev = { device = "UUID=33ea92b1-271c-49ab-baee-b70a3fdf9264"; };
    luks-81a33a7b-6315-42fd-9cde-8ac06193a29d = { device = "UUID=81a33a7b-6315-42fd-9cde-8ac06193a29d"; allowDiscards = true; keyFile = "/keyfile:UUID=4f3552e5-22d2-44f0-8f2d-ddf004f2db7e"; };
    luks-e4b011c9-6a60-452f-aaa6-b4724d44fb5d = { device = "UUID=e4b011c9-6a60-452f-aaa6-b4724d44fb5d"; allowDiscards = true; keyFile = "/keyfile:UUID=4f3552e5-22d2-44f0-8f2d-ddf004f2db7e"; };
  };
}
