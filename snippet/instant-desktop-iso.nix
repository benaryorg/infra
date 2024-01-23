{
  inputs.benaryorg.url = "git+https://git.shell.bsocat.net/infra.git";
  inputs.benaryorg.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs.url = "tarball+https://git.shell.bsocat.net/nixpkgs/snapshot/nixpkgs-nixos-23.11.tar.gz";

  outputs = { self, benaryorg, ... }:
  {
    nixosConfigurations.iso = benaryorg.inputs.nixpkgs.lib.nixosSystem
    {
      system = "x86_64-linux";
      specialArgs =
      {
        name = "iso.home.bsocat.net";
        nodes = builtins.listToAttrs (builtins.map (node: { name = node.config.networking.fqdn; value = node; }) (builtins.attrValues benaryorg.nixosConfigurations));
      };
      modules =
      [
        benaryorg.nixosModules.default
        (benaryorg.inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/iso-image.nix")
        ({ pkgs, lib, ... }:
        {
          # most of this here is a copy from the iso build, adjust as needed
          benaryorg.base.lightweight = true;
          benaryorg.net.type = "manual";
          benaryorg.net.resolver = "resolved";
          benaryorg.hardware.vendor = "none";
          # since the client will not be added dynamically, substitution will have to do
          benaryorg.build.role = "client-light";
          # this here is *required* otherwise the flake.nix file will be overwritten immediately
          benaryorg.flake.enable = false;

          isoImage =
          {
            isoBaseName = "katze";
            makeBiosBootable = true;
            makeEfiBootable = true;
            makeUsbBootable = true;
          };

          environment.etc.built-from.source = ./flake.nix;

          environment.systemPackages = with pkgs;
          [
            firefox
          ];

          networking.useDHCP = lib.mkForce true;
          networking.wireless.enable = true;
          networking.wireless.networks =
          {
            LitterBox = { psk = "Your Password Here!"; };
          };

          systemd.services."serial-getty@ttyS0" =
          {
            enable = true;
            wantedBy = [ "getty.target" ];
          };

          users.users.benaryorg.hashedPassword = "";

          services =
          {
            getty.autologinUser = "root";
            resolved.extraConfig = lib.mkForce "";
            xserver =
            {
              enable = true;
              layout = "de";
              xkbVariant = "neo";
              displayManager =
              {
                autoLogin.enable = true;
                autoLogin.user = "benaryorg";
              };
              desktopManager =
              {
                xfce.enable = true;
                xfce.enableScreensaver = false;
              };
            };
          };

          hardware.enableRedistributableFirmware = true;
          hardware.opengl = { enable = true; driSupport = true; };
          zramSwap = { enable = true; memoryPercent = 200; };
        })
      ];
    };
  };
}
