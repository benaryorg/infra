{ pkgs, lib, config, ... }:
{
  boot.initrd.supportedFilesystems = [ "ext4" "vfat" "btrfs" ];
  boot.supportedFilesystems = [ "ext4" "vfat" "btrfs" ];
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;
  # efibootmgr -c -b 4 --disk /dev/nvme0n1 --label nixos --loader '\default\kernel' -u 'initrd=\default\initrd loglevel=4 verbose'
  boot.loader.external =
  {
    enable = true;
    installHook = pkgs.writeShellScript "copy-kernel"
    ''
      #! ${pkgs.zsh}
      set -e

      system=''${1?"no system provided"}
      if ! test -e $system; then
        printf "system %q does not exist\\n" $system
        false
      fi

      jq=${pkgs.jq}/bin/jq

      kernel=$($jq -r '.["org.nixos.bootspec.v1"].kernel' $system/boot.json)
      initrd=$($jq -r '.["org.nixos.bootspec.v1"].initrd' $system/boot.json)
      init=$($jq -r '.["org.nixos.bootspec.v1"].init' $system/boot.json)

      ${pkgs.coreutils}/bin/mkdir -p /boot/default
      ${pkgs.coreutils}/bin/install --group=root --owner=root --mode=644 /boot/default/kernel /boot/default/kernel.old || true
      ${pkgs.coreutils}/bin/install --group=root --owner=root --mode=644 /boot/default/initrd /boot/default/initrd.old || true
      ${pkgs.coreutils}/bin/install --group=root --owner=root --mode=644 $kernel /boot/default/kernel
      ${pkgs.coreutils}/bin/install --group=root --owner=root --mode=644 $initrd /boot/default/initrd
      ${pkgs.coreutils}/bin/mkdir -p /sbin
      ${pkgs.coreutils}/bin/ln -sf $system/init /sbin/init

      true
    '';
  };
  boot.initrd.systemd.services.initrd-nixos-activation.script = lib.mkForce
  ''
    set -euo pipefail
    export PATH="/bin:${config.boot.initrd.systemd.package.util-linux}/bin"
    init="$(readlink /sysroot/sbin/init)"
    closure="$(dirname "$init")"
    echo 'NEW_INIT=' > /etc/switch-root.conf
    mkdir -p /sysroot/run
    mount --bind /run /sysroot/run
    export IN_NIXOS_SYSTEMD_STAGE1=true
    exec chroot /sysroot "$closure/prepare-root"
  '';

  boot.swraid =
  {
    enable = true;
    mdadmConf = "MAILADDR root@benary.org";
  };

  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices =
  {
    keydev = { device = "UUID=33ea92b1-271c-49ab-baee-b70a3fdf9264"; };
    luks-81a33a7b-6315-42fd-9cde-8ac06193a29d = { device = "UUID=81a33a7b-6315-42fd-9cde-8ac06193a29d"; allowDiscards = true; keyFile = "/keyfile:UUID=4f3552e5-22d2-44f0-8f2d-ddf004f2db7e"; };
    luks-e4b011c9-6a60-452f-aaa6-b4724d44fb5d = { device = "UUID=e4b011c9-6a60-452f-aaa6-b4724d44fb5d"; allowDiscards = true; keyFile = "/keyfile:UUID=4f3552e5-22d2-44f0-8f2d-ddf004f2db7e"; };
  };
}
