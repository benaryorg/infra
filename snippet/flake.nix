# this is a flake.nix for /etc/nixos which uses the provided nixosModule to get going
# Many of the parameters will have to be tweaked, for instance benaryorg.hardware and benaryorg.net are certain to require attention.

{
  inputs.benaryorg.url = "git+https://git.shell.bsocat.net/infra.git?ref=module";

  outputs = { self, benaryorg, ... }:
  {
    # don't forget to name your host
    nixosConfigurations.foobar = benaryorg.inputs.nixpkgs.lib.nixosSystem
    {
      system = "x86_64-linux";
      specialArgs =
      {
        # otherwise the colmena-specific stuff breaks
        name = "foobar.example.com";
        # can be set to an empty attrSet instead, however you can reference upstream
        # this allows e.g. benaryorg.build to still work for substituters
        nodes = benaryorg.nixosConfigurations;
      };
      modules =
      [
        # generated using nixos-generate-config
        ./hardware-configuration.nix
        # this is the upstream module
        benaryorg.nixosModules.default
        # custom configuration goes here
        ({ pkgs, ... }:
        {
          # most of this here is a copy from the iso build, adjust as needed
          benaryorg.base.lightweight = true;
          benaryorg.net.type = "none";
          benaryorg.hardware.vendor = "none";
          # since the client will not be added dynamically, substitution will have to do
          benaryorg.build.role = "client-light";
          # it will still work due to the nodes specialArgs
          benaryorg.build.tags = [ "shell.bsocat.net" ];
          # this here is *required* otherwise the flake.nix file will be overwritten immediately
          benaryorg.flake.enable = false;

          # do whatever else you wanna do (you *can* use the modules for networking and booting though):

          boot.loader.grub.enable = false;
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = false;

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
        })
      ];
    };
  };
}
