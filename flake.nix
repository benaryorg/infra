{
  inputs =
  {
    nixpkgs.url = "git+https://git.shell.bsocat.net/nixpkgs?ref=nixos-23.11";
    nixpkgs-unstable.url = "git+https://git.shell.bsocat.net/nixpkgs?ref=nixos-unstable";
    ragenix.url = "git+https://git.shell.bsocat.net/ragenix";
    ragenix.inputs.nixpkgs.follows = "nixpkgs-unstable";
    ragenix.inputs.agenix.follows = "agenix";
    ragenix.inputs.flake-utils.follows = "flake-utils";
    ragenix.inputs.rust-overlay.follows = "rust-overlay";
    ragenix.inputs.crane.follows = "crane";
    colmena.url = "git+https://git.shell.bsocat.net/colmena";
    colmena.inputs.nixpkgs.follows = "nixpkgs";
    colmena.inputs.stable.follows = "nixpkgs";
    colmena.inputs.flake-compat.follows = "flake-compat";
    colmena.inputs.flake-utils.follows = "flake-utils";
    agenix.url = "git+https://git.shell.bsocat.net/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";
    agenix.inputs.darwin.follows = "darwin";
    agenix.inputs.systems.follows = "nix-systems";
    flake-compat.url = "git+https://git.shell.bsocat.net/flake-compat";
    flake-compat.flake = false;
    flake-utils.url = "git+https://git.shell.bsocat.net/flake-utils";
    flake-utils.inputs.systems.follows = "nix-systems";
    rust-overlay.url = "git+https://git.shell.bsocat.net/rust-overlay";
    rust-overlay.inputs.flake-utils.follows = "flake-utils";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    benaryorg-website.url = "git+https://git.shell.bsocat.net/benary.org";
    benaryorg-website.inputs.flake-utils.follows = "flake-utils";
    benaryorg-website.inputs.nixpkgs.follows = "nixpkgs";
    crane.url = "git+https://git.shell.bsocat.net/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    nix-systems.url = "git+https://git.shell.bsocat.net/nix-systems";
    home-manager.url = "git+https://git.shell.bsocat.net/home-manager?ref=release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "git+https://git.shell.bsocat.net/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    lxddns.url = "git+https://git.shell.bsocat.net/lxddns";
    lxddns.inputs.nixpkgs.follows = "nixpkgs";
    lxddns.inputs.flake-utils.follows = "flake-utils";
    lxddns.inputs.systems.follows = "nix-systems";
  };

  outputs = { self, nixpkgs, colmena, ragenix, benaryorg-website, lxddns, ... }:
    let
      lib = nixpkgs.lib;
      colmenaStaticConfig =
      {
        meta =
        {
          nixpkgs = nixpkgs.legacyPackages.x86_64-linux;
          allowApplyAll = false;
        };

        defaults = { name, nodes, pkgs, lib, config, options, ... }:
        {
          imports =
          [
            self.nixosModules.default
          ];
          config =
          {
            deployment =
            {
              targetHost = name;
              targetUser = config.benaryorg.user.ssh.name;
              privilegeEscalationCommand = [ "sudo" "-H" "TMPDIR=/nix/tmp" "--" ];
              tags = config.benaryorg.deployment.tags;
              buildOnTarget = true;
            };
            security.acme.acceptTerms = true;
            security.acme.defaults.email = "letsencrypt@benary.org";
          };
        };

        "benaryorg1.lxd.bsocat.net" = import ./config/template/website-container;
        "benaryorg2.lxd.bsocat.net" = import ./config/template/website-container;
        "benaryorg3.lxd.bsocat.net" = import ./config/template/website-container;
      };
      # generate config from subdirectories
      colmenaDynamicConfig = lib.pipe (builtins.readDir ./config/host)
      [
        lib.attrsToList
        # only accept files and directories
        (builtins.filter ({ value, ... }: value == "directory" || value == "regular"))
        # remove hidden files/dirs
        (builtins.filter ({ name, ... }: !(lib.hasPrefix "." name)))
        # remove non-nix files
        (builtins.filter ({ name, value }: value == "directory" || lib.hasSuffix ".nix" name))
        # map to appropriate import
        (builtins.map ({ name, value }:
          builtins.getAttr value
          {
            directory = { name = name; value = import ((builtins.toPath ./config/host) + "/${name}"); };
            regular = { name = lib.removeSuffix ".nix" name; value = import ((builtins.toPath ./config/host) + "/${name}"); };
          }
        ))
        # back to attrs
        lib.listToAttrs
      ];
      # merge the dynamic with the static config
      colmenaConfig = colmenaDynamicConfig // colmenaStaticConfig;
      # build the hive
      colmenaHive = colmena.lib.makeHive colmenaConfig;
      # remove fake hosts
      hosts = builtins.filter (name: !colmenaHive.nodes.${name}.config.benaryorg.deployment.fake) (builtins.attrNames colmenaHive.nodes);
      # create a nixosConfiguration entry
      buildNixosKv = name:
      {
        name = colmenaHive.nodes.${name}.config.networking.hostName;
        value = colmenaHive.nodes.${name};
      };
      # merge the nixosConfiguration entries
      nixosConfig = builtins.listToAttrs (builtins.map buildNixosKv hosts);
      # create a node Hydra job
      buildHydraNodeJobKv = name:
      {
        name = let
            hostname = colmenaHive.nodes.${name}.config.networking.hostName;
          in
            "node-${hostname}";
        value = colmenaHive.nodes.${name}.config.system.build.toplevel
          //
            {
              meta.description = "hydra build for colmena node ${name}";
            };
      };
      # hydra node jobs
      hydraNodeJobs = builtins.listToAttrs (builtins.map buildHydraNodeJobKv hosts);
      # hydra extra jobs
      hydraExtraJobs =
      {
        kexec = colmenaHive.nodes."kexec.example.com".config.system.build.kexecTree;
        iso = colmenaHive.nodes."iso.example.com".config.system.build.isoImage;
        lxc = colmenaHive.nodes."lxc.example.com".config.system.build.tarball;
        lxc-metadata = colmenaHive.nodes."lxc.example.com".config.system.build.metadata;
      };
      addHydraMeta = name: { meta ? {}, ... }@value: value //
      {
        meta =
          let
            metaDefault = name: default: if builtins.hasAttr name meta then builtins.getAttr name meta else default;
            metaMerge = attrs: meta // (builtins.mapAttrs metaDefault attrs);
          in
            metaMerge
            {
              description = "hydra job ${name}";
              license = [ { shortName = "AGPL-3.0-or-later"; } ];
              homepage = "https://git.shell.bsocat.net/infra/";
              maintainers = [ { email = "root@benary.org"; } ];
              schedulingPriority = 10;
              timeout = 36000;
              maxSilent = 7200;
            };
      };
      nixosModules = rec
      {
        benaryorg =
        {
          imports =
          [
            ragenix.nixosModules.default
            benaryorg-website.nixosModules.default
            lxddns.nixosModules.default
            ./spec/base.nix
            ./spec/deployment.nix
            ./spec/user.nix
            ./spec/ssh.nix
            ./spec/nix.nix
            ./spec/flake.nix
            ./spec/nullmailer.nix
            ./spec/hardware.nix
            ./spec/git.nix
            ./spec/net.nix
            ./spec/prometheus.nix
            ./spec/lxd.nix
            ./spec/build.nix
            ./spec/acme.nix
          ];

          config =
          {
            nixpkgs.overlays = [ benaryorg-website.overlays.default ragenix.overlays.default lxddns.overlays.default ];
            benaryorg.user.ssh.keys = lib.mkOrder 1000 [ nixosConfig.shell.config.benaryorg.ssh.userkey.benaryorg ];
          };
        };
        default = benaryorg;
      };
    in
      {
        colmena = colmenaConfig;
        nixosConfigurations = nixosConfig;
        nixosModules = nixosModules;
        hydraJobs = builtins.mapAttrs addHydraMeta (hydraNodeJobs // hydraExtraJobs);
      };
}
