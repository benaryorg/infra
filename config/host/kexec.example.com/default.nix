{ nodes, pkgs, lib, config, modulesPath, ... }:
{
  benaryorg.deployment.fake = true;

  imports =
  [
    (modulesPath + "/installer/netboot/netboot.nix")
  ];

  benaryorg.base.lightweight = true;
  benaryorg.net.type = "none";
  benaryorg.hardware.vendor = "none";
  benaryorg.flake.enable = false;
  benaryorg.build.role = "client-light";
  benaryorg.build.tags = [ "cloud.bsocat.net" ];
  benaryorg.user.ssh.keys = lib.mkAfter [ nodes."gnutoo.home.bsocat.net".config.benaryorg.ssh.userkey.benaryorg ];
  users.users.root.openssh.authorizedKeys.keys = [ nodes."shell.cloud.bsocat.net".config.benaryorg.ssh.userkey.benaryorg nodes."gnutoo.home.bsocat.net".config.benaryorg.ssh.userkey.benaryorg ];

  hardware.enableRedistributableFirmware = true;
  boot.swraid.enable = true;
  # remove warning about unset mail
  boot.swraid.mdadmConf = "PROGRAM ${pkgs.coreutils}/bin/true";
  systemd.services."serial-getty@ttyS0" =
  {
    enable = true;
    wantedBy = [ "getty.target" ];
  };
  services =
  {
    getty.autologinUser = "root";
    lldpd.enable = true;
    unbound.enable = true;
    openssh = lib.mkForce
    {
      enable = true;
      settings =
      {
        PermitRootLogin = "yes";
        PasswordAuthentication = false;
      };
    };
  };
  networking =
  {
    firewall.enable = false;
    wireguard.enable = false;
    tempAddresses = "disabled";
    useDHCP = true;
  };
}
