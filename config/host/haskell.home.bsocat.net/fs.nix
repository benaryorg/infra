{ pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [ ceph-client ];

  fileSystems =
  {
    "/boot" =
    {
      device = "/dev/disk/by-uuid/0511-35B4";
      neededForBoot = true;
      options = [ "noatime" ];
    };
    "/" =
    {
      device = "/dev/disk/by-uuid/3e49ad64-08ad-4ab9-95c0-466e108cf263";
      options = [ "noatime" "compress=zstd" "degraded" "space_cache=v2" "discard=async" "subvol=@" ];
    };
  };

  services.btrfs.autoScrub =
  {
    enable = true;
    fileSystems = [ "/" ];
    interval = "weekly";
  };

  systemd.mounts = lib.mkAfter
  [
    {
      what = "tmpfs";
      type = "tmpfs";
      where = "/nix/tmp";
      mountConfig.Options = "strictatime,rw,nosuid,nodev,size=16Gi";
    }
  ];
}
