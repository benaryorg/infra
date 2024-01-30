{ pkgs, lib, config, ... }:
{
  users.users.benaryorg.extraGroups = lib.mkAfter [ "ipfs" ];

  services.kubo =
  {
    enable = true;
    enableGC = true;
  };
  systemd.slices.kubo =
  {
    enable = true;
    description = "Slice for kubo/IPFS.";
    sliceConfig.MemoryHigh = "4G";
    sliceConfig.MemoryMax = "5G";
  };
  systemd.services.ipfs.serviceConfig.Slice = "kubo.slice";
  # specifically disable the config merging for now
  # this shall be improved upon in the future
  systemd.services.ipfs.preStart = lib.mkForce "";

  systemd.services.ipfs-pin-sync =
  {
    description = "sync IPFS pins stored in MFS";
    after = [ "network-online.target" "ipfs-api.socket" ];
    wants = [ "ipfs-api.socket" ];
    serviceConfig =
    {
      Type = "oneshot";
      User = config.services.kubo.user;
      Group = config.services.kubo.group;
    };
    environment.IPFS_PATH = config.services.kubo.dataDir;
    path = with pkgs; [ kubo util-linux moreutils gnugrep util-linux zsh ];
    script =
    ''
      set -e
      test -e $IPFS_PATH/repo.lock
      ipfs cat /ipns/12D3KooWNoPhenCQSsdfKJvJ8g2R1bHbw7M7s5arykhqJCVd5F2B/meta/update-pins | ifne flock -e -w 4 $IPFS_PATH zsh
    '';
  };
  systemd.timers.ipfs-pin-sync =
  {
    description = "sync IPFS pins stored in MFS";
    after = [ "network-online.target" "ipfs-api.socket" ];
    wantedBy = [ "timers.target" ];
    timerConfig =
    {
      OnUnitInactiveSec = 60;
      OnBootSec = 600;
      Persistent = true;
    };
  };
}
