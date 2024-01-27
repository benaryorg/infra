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
}
