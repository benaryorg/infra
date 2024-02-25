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

  # TODO:
  #  - bootloader funkiness as module

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
    users.users.benaryorg.packages = with pkgs; [ gnupg vim-full ceph kubo imagemagick ffmpeg-full ];

    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;
    hardware.enableRedistributableFirmware = true;

    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    boot.kernelModules = lib.mkAfter [ "ceph" "rbd" ];
    virtualisation.incus.enable = true;
    users.groups.incus-admin.members = [ "benaryorg" ];
    # FIXME: the Gentoo incus install was too new at the time
    # remove when https://github.com/NixOS/nixpkgs/pull/284009 hits any release
    # I do not want to follow unstable here because unstable would potentially update further than the next release
    nixpkgs.overlays = lib.mkAfter
    [
      (_final: prev:
      {
        incus-unwrapped = prev.incus-unwrapped.override
        {
          buildGoModule = args:
            # intentionally break on newer version
            assert args.version == "0.4.0";
            prev.buildGoModule (args // rec
            {
              version = "0.5.1";
              src = prev.fetchFromGitHub
              {
                owner = "lxc";
                repo = "incus";
                rev = "refs/tags/v${version}";
                hash = "sha256-3eWkQT2P69ZfN62H9B4WLnmlUOGkpzRR0rctgchP+6A=";
              };
              vendorHash = "sha256-2ZJU7WshN4UIbJv55bFeo9qiAQ/wxu182mnz7pE60xA=";
            });
        };
      })
    ];
    systemd.services.incus.path = lib.mkAfter [ pkgs.ceph-client ];
    systemd.services.incus.after = lib.mkAfter [ "ceph.target" ];

    virtualisation.libvirtd.enable = true;
    virtualisation.libvirtd.onShutdown = "shutdown";
    virtualisation.libvirtd.qemu.package = pkgs.qemu_full;

    zramSwap = { enable = true; memoryPercent = 400; };

    console.keyMap = "neo";

    system.stateVersion = "23.11";
  };
}
