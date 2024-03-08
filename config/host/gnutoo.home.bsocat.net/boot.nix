{
  boot.initrd.supportedFilesystems = [ "ext2" "ext4" "vfat" "btrfs" ];
  boot.supportedFilesystems = [ "ext2" "ext4" "vfat" "btrfs" ];
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices =
  {
    keydev = { device = "UUID=3c9f7859-8bec-409a-9a6a-b241cd5222dc"; };
    luks-b9b6f3dd-8a6d-4677-9d2f-1cfc10f50490 = { device = "UUID=b9b6f3dd-8a6d-4677-9d2f-1cfc10f50490"; allowDiscards = true; keyFile = "/keyfile:UUID=641a2644-06d2-4fbb-9276-3f477dff74e3"; };
    luks-daddd026-0aff-4fe2-b531-0be0ba5df3fd = { device = "UUID=daddd026-0aff-4fe2-b531-0be0ba5df3fd"; allowDiscards = true; keyFile = "/keyfile:UUID=641a2644-06d2-4fbb-9276-3f477dff74e3"; };
  };
}
