{ nodes, pkgs, lib, config, ... }:
{
  imports =
  [
    ./boot.nix
    ./net.nix
    ./btrbk.nix
    ./fs.nix
    ./audio.nix
    ./desktop.nix
    ./ceph.nix
    ./wireguard.nix
  ];

  config =
  {
    benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL7UUWml2/m0MW3A7rZbnXfgpa6uFcEaDjvm0mxwOypu";
    benaryorg.ssh.userkey.benaryorg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKubEmPiQTJCpFuXhubW3SDlxoBXK+sFhcHsUH6kz32p";

    benaryorg.user.ssh.keys = lib.mkAfter [ nodes."gnutoo.home.bsocat.net".config.benaryorg.ssh.userkey.benaryorg ];

    benaryorg.hardware.vendor = "none";
    benaryorg.prometheus.client.enable = true;

    # during development
    benaryorg.flake.autoupgrade = false;

    # do whatever else you wanna do (you *can* use the modules for networking and booting though):

    security.acme.certs.${config.networking.fqdn}.listenHTTP = ":80";

    users.users.benaryorg.initialPassword = "1234";
    users.users.benaryorg.group = "benaryorg";
    users.groups.benaryorg.gid = 1000;

    xdg.portal.enable = true;
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    xdg.portal.config.common.default = "gtk";
    services.flatpak.enable = true;
    users.users.benaryorg.packages = with pkgs; [ gnupg vim-full ceph kubo imagemagick ffmpeg-full obs-studio ];

    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;
    hardware.bluetooth.package = pkgs.bluez.overrideAttrs ({ nativeBuildInputs, postInstall, ... }:
    {
      version = "5.72";
      nativeBuildInputs = nativeBuildInputs ++ [ pkgs.python3.pkgs.pygments ];
      postInstall =
      ''
        mkdir -p $out/etc/bluetooth
        touch $out/etc/bluetooth/{main,input,network}.conf
        ${postInstall}
      '';
      src = pkgs.fetchurl
      {
        url = "mirror://kernel/linux/bluetooth/bluez-5.72.tar.xz";
        hash = "sha256-SZ1/o0WplsG7ZQ9cZ0nh2SkRH6bs4L4OmGh/7mEkU24=";
      };
    });

    nixpkgs.config.allowUnfree = true;
    hardware.steam-hardware.enable = true;

    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    boot.kernelModules = lib.mkAfter [ "ceph" "rbd" ];
    virtualisation.incus =
    {
      enable = true;
      socketActivation = false;
      softDaemonRestart = false;
    };
    users.groups.incus-admin.members = [ "benaryorg" ];
    systemd.services.incus.path = lib.mkAfter [ pkgs.ceph-client ];
    systemd.services.incus.after = lib.mkAfter [ "ceph.target" ];

    virtualisation.libvirtd.enable = true;
    virtualisation.libvirtd.onShutdown = "shutdown";
    virtualisation.libvirtd.qemu.package = pkgs.qemu_full;

    powerManagement.cpuFreqGovernor = "schedutil";

    zramSwap = { enable = true; memoryPercent = 400; };

    console.keyMap = "neo";

    system.stateVersion = "24.05";
  };
}
