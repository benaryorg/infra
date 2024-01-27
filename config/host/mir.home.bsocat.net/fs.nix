{ pkgs, lib, config, ... }:
{
  environment.systemPackages = with pkgs; [ ceph-client ];

  fileSystems =
  {
    "/boot" =
    {
      device = "/dev/disk/by-uuid/9E41-950C";
      neededForBoot = true;
      options = [ "noatime" ];
    };
    "/" =
    {
      device = "/dev/disk/by-uuid/b15cba1b-2ed1-444b-9702-e42bf810bea9";
      options = [ "noatime" "compress=zstd" "degraded" "space_cache=v2" "discard=async" "subvol=@" ];
    };
    "/srv/cephfs/benaryorg" =
    {
      device = "[2a0c:b641:a40::264b:feff:fe90:7474]:3301:/";
      fsType = "ceph";
      options = [ "noatime" "name=admin" "fs=benaryorg" "ms_mode=secure" "nofail" "x-systemd.after=ceph.target" ];
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
