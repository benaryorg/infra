{ pkgs, lib, config, ... }:
{
  environment.systemPackages = with pkgs; [ ceph-client ];

  boot.kernelModules = [ "ceph" ];
  fileSystems =
  {
    "/boot" =
    {
      device = "/dev/disk/by-uuid/0324-0E84";
      neededForBoot = true;
      options = [ "noatime" ];
    };
    "/" =
    {
      device = "/dev/disk/by-uuid/fc3d9734-1ad0-4bec-96a1-c9468f97408e";
      options = [ "noatime" "compress=zstd" "degraded" "space_cache=v2" "discard=async" "subvol=@nixos" ];
    };
    "/mnt/cephfs/benaryorg" =
    {
      device = "mir.home.bsocat.net:3301:/";
      fsType = "ceph";
      options = [ "noatime" "name=gnutoo" "fs=benaryorg" "ms_mode=secure" "nofail" "_netdev" ];
    };
  };
  services.btrfs.autoScrub =
  {
    enable = true;
    fileSystems = [ "/" ];
    interval = "weekly";
  };
  environment.etc."ceph/ceph.conf".source = ./file/ceph.conf;
}
