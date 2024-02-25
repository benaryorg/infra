{ config, lib, ... }:
{
  options =
  {
    benaryorg.home-manager =
    {
      enable = lib.mkOption
      {
        default = true;
        description = lib.mdDoc "Whether to enable home-manager defaults.";
        type = lib.types.bool;
      };
      perUserSettings = lib.mkOption
      {
        default = {};
        description = lib.mdDoc
        ''
          Users and their enabled modules.
          The idea is that NixOS modules can register their home-manager modules using {option}`home-manager.sharedModules`, and then use this option to enable them.
          The pattern is something along these lines:

          ```nix
          # in NixOS module called mymodule
          config =
          {
            benaryorg.home-manager.perUserSettings.''${config.mymodule.defaultUser}.mymodule.enable = lib.mkDefault config.mymodule.enable;
            home-manager.sharedModules = lib.mkAfter
            [
              ({ lib, config, ... }:
              {
                options =
                {
                  mymodule.enable = lib.mkEnableOption "my module";
                };
                config = lib.mkIf config.mymodule.enable
                {
                  # do the thing
                };
              })
            ];
          };
          ```

          This automatically adds the module in all cases but leaves it disabled by default for all users.
          For the "default" user, often defaulting to {option}`benaryorg.ssh.user`, the module is enabled, but using `lib.mkDefault` which allows easy overrides in case functionality is desired to be cherry-picked from the module.

          Any other user can still opt into the module using:
          
          ```nix
          benaryorg.home-manager.perUserSettings.my-other-user.mymodule.enable = true;
          ```
        '';
        default = {};
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
      };
    };
  };

  config = 
    let
      cfg = config.benaryorg.home-manager;
    in
      lib.mkIf cfg.enable
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users = builtins.mapAttrs (_user: settings: _args:
          {
            config = 
              {
                # breaks when on IPv6-only because upstream pulls a tarball directly from source hut which is Legacy IP only
                # see: https://github.com/nix-community/home-manager/issues/4966
                manual.html.enable = false;
                manual.manpages.enable = false;
                manual.json.enable = false;
              }
                // settings // { home.stateVersion = config.system.stateVersion; };
          }) cfg.perUserSettings;
      };
}
