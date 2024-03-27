{
  boot.initrd.supportedFilesystems = [ "ext4" "vfat" "btrfs" ];
  boot.supportedFilesystems = [ "ext4" "vfat" "btrfs" ];
  boot.initrd.availableKernelModules = [ "mpt3sas" ];

  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  boot.kernelParams = [ "console=ttyS0,115200" ];

  boot.swraid =
  {
    enable = true;
    mdadmConf = "MAILADDR root@benary.org";
  };

  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices =
  {
    keydev = { device = "UUID=bbf5b89e-1f8a-4146-9523-032694a4b7da"; };
    luks-6aa9f5ac-d48a-4aa9-ab0b-501e64704b08 = { device = "UUID=6aa9f5ac-d48a-4aa9-ab0b-501e64704b08"; allowDiscards = true; keyFile = "/keyfile:UUID=0d2a7e08-82e8-4510-ad6d-afa435fbbd11"; };
    luks-4a8c2abe-6094-488a-81ce-db696123bbd2 = { device = "UUID=4a8c2abe-6094-488a-81ce-db696123bbd2"; allowDiscards = true; keyFile = "/keyfile:UUID=0d2a7e08-82e8-4510-ad6d-afa435fbbd11"; };
  };
}
