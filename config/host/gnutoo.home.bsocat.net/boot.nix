{ pkgs, lib, config, ... }:
{
  boot.initrd.supportedFilesystems = [ "ext2" "ext4" "vfat" "btrfs" ];
  boot.supportedFilesystems = [ "ext2" "ext4" "vfat" "btrfs" ];
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;
  # efibootmgr -c -b 3 --disk /dev/sda --label nixos --loader '\default\kernel' -u 'initrd=\default\initrd loglevel=4 verbose'
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

  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices =
  {
    keydev = { device = "UUID=3c9f7859-8bec-409a-9a6a-b241cd5222dc"; };
    luks-b9b6f3dd-8a6d-4677-9d2f-1cfc10f50490 = { device = "UUID=b9b6f3dd-8a6d-4677-9d2f-1cfc10f50490"; allowDiscards = true; keyFile = "/keyfile:UUID=641a2644-06d2-4fbb-9276-3f477dff74e3"; };
    luks-daddd026-0aff-4fe2-b531-0be0ba5df3fd = { device = "UUID=daddd026-0aff-4fe2-b531-0be0ba5df3fd"; allowDiscards = true; keyFile = "/keyfile:UUID=641a2644-06d2-4fbb-9276-3f477dff74e3"; };
  };
}
