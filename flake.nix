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
    njconnect.url = "git+https://git.shell.bsocat.net/nix-njconnect";
    njconnect.inputs.nixpkgs.follows = "nixpkgs";
    njconnect.inputs.flake-utils.follows = "flake-utils";
    njconnect.inputs.systems.follows = "nix-systems";
  };

  outputs = { self, nixpkgs, colmena, ... }@args:
    let
      lib = nixpkgs.lib;
      withSshKey = key: module:
      {
        imports =
        [
          module
        ];

        config =
        {
          benaryorg.ssh.hostkey = key;
        };
      };
      colmenaStaticConfig =
      {
        meta =
        {
          nixpkgs = nixpkgs.legacyPackages.x86_64-linux;
          specialArgs =
          {
            benaryorg-flake = self;
          };
          allowApplyAll = false;
        };

        defaults = { name, config, ... }:
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

        "benaryorg1.lxd.bsocat.net" = withSshKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDp4Snx4pM3+8yOVEV/VkdphtSeA7Wh7jAYAMdx75N3e" ./config/template/website-container;
        "benaryorg2.lxd.bsocat.net" = withSshKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPXO1VPYJ5YfvCT4wvTWauSSLtmHS2gG8jh7RQyu6hy+" ./config/template/website-container;
        "benaryorg3.lxd.bsocat.net" = withSshKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILyYvEMA/opKvs5IcnRdCZmUqg941x6umlf1I0/Sn5sh" ./config/template/website-container;
        "certbox.lxd.bsocat.net" = withSshKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIl6chz1TtkfGY6VT4qZbwcqTRxVpaPXg2Z/Wf6cTZ/" ./config/template/legacy-backup-client;
        "dav.lxd.bsocat.net" = withSshKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICYOtWABsT9IrCIFSDpOCoZPRoa+OnBwA+RaIZTIirF8" ./config/template/legacy-backup-client;
        "imap1.lxd.bsocat.net" = withSshKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL8A9BN1hkRCgGTLEpt/vWlhoGmsqdhvEaJKMArZvALf" ./config/template/legacy-backup-client;
        "imap2.lxd.bsocat.net" = withSshKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMwOz08g0/UvpN8/mAzSwfVMWYnFDnS/Rbn1RYyX9Myp" ./config/template/legacy-backup-client;
        "puppet.lxd.bsocat.net" = withSshKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB/um+R+g6D1xd0GSbDLX9OTCpSP7qFBRvYFwAYyP9Eu" ./config/template/legacy-backup-client;
        "smtp1.lxd.bsocat.net" = withSshKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGfVpEHgHkwFKNdSi/ZZTbltcu3tN8jJ/QbNESLRpdou" ./config/template/legacy-backup-client;
        "smtp2.lxd.bsocat.net" = withSshKey "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUSA20wO7I2cC7PWnjUeXKvd+NRmKcGZsdlnMkJxCpz" ./config/template/legacy-backup-client;
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
            directory = { name = name; value = import (./config/host + "/${name}"); };
            regular = { name = lib.removeSuffix ".nix" name; value = import (./config/host + "/${name}"); };
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
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          srcdir = ./.;
        in
          {
            lint-deadnix = pkgs.runCommand "infra-deadnix" {} "${pkgs.deadnix}/bin/deadnix --fail -- ${srcdir} | tee /dev/stderr > $out";
            lint-statix = pkgs.runCommand "infra-statix" {} "${pkgs.statix}/bin/statix check --config ${srcdir}/statix.toml -- ${srcdir} | tee /dev/stderr > $out";

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
            args.ragenix.nixosModules.default
            args.benaryorg-website.nixosModules.default
            args.lxddns.nixosModules.default
            args.home-manager.nixosModules.default
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
            ./spec/desktop
            ./spec/home-manager.nix
            ./spec/backup.nix
          ];

          config =
          {
            nixpkgs.overlays =
            [
              args.benaryorg-website.overlays.default
              args.ragenix.overlays.default
              args.lxddns.overlays.default
              args.njconnect.overlays.default
            ];
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
