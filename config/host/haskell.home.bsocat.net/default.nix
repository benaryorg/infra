{ nodes, pkgs, lib, config, ... }:
{
  imports =
  [
    ./boot.nix
    ./net.nix
    ./fs.nix
    ./ceph.nix
  ];

  config =
  {
    benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFMd42S955LiTV/+nFvoWpxkDe2Qqm1v59d+XLhc/RS0";

    benaryorg.user.ssh.keys = lib.mkAfter [ nodes."gnutoo.home.bsocat.net".config.benaryorg.ssh.userkey.benaryorg ];

    benaryorg.hardware.vendor = "none";
    benaryorg.prometheus.client.enable = true;
    benaryorg.flake.autoupgrade = true;

    security.acme.certs.${config.networking.fqdn}.listenHTTP = ":80";

    # save some money
    powerManagement.cpuFreqGovernor = "powersave";
    users.users.benaryorg.packages = with pkgs; [ ceph ];

    zramSwap = { enable = true; memoryPercent = 400; };

    console.keyMap = "neo";
    # actual serial <3
    systemd.services."serial-getty@ttyS0" =
    {
      enable = true;
      wantedBy = [ "getty.target" ];
    };

    system.stateVersion = "24.05";
  };
}
