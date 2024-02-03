{ name, nodes, pkgs, lib, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHcgG0ngQ0kAARuIIuh6V43uObAnFBZsGCgxFs/OvW62";

  benaryorg.prometheus.client.enable = true;
  benaryorg.build.tags = [ "shell.bsocat.net" "aarch64-linux" ];

  benaryorg.backup.client.directories =
  [
    config.services.postgresqlBackup.location
    "/var/lib/hydra/build-logs"
  ];
  services.postgresqlBackup.enable = true;

  services.nginx =
  {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts =
    {
      ${config.networking.fqdn} =
      {
        forceSSL = true;
        enableACME = true;
        locations."/".proxyPass = "http://127.0.0.1:3000/";
      };
    };
  };
  services.hydra =
  {
    enable = true;
    hydraURL = "https://${config.networking.fqdn}/";
    useSubstitutes = true;
    notificationSender = "hydra@benary.org";
    buildMachinesFiles = lib.pipe config.nix.buildMachines
    [
      (builtins.map (machine: builtins.concatStringsSep " "
        [
          "${machine.protocol}://${machine.sshUser}@${machine.hostName}"
          (builtins.concatStringsSep "," machine.systems)
          # overwrite the ssh key
          # hydra uses its key manually, not via nix, so it doesn't have root permissions for this
          "/run/credentials/hydra-queue-runner.service/ssh_hydra_ed25519_key"
          # number of build jobs, defaults to 1 otherwise
          "42"
          "1"
          (builtins.concatStringsSep "," machine.supportedFeatures)
          "-"
          "-"
        ]
      ))
      (builtins.concatStringsSep "\n")
      (pkgs.writers.writeText "hydra-machines")
      lib.singleton
    ];
  };
  systemd.slices.build =
  {
    enable = true;
    description = "Slice for all services doing build jobs or similar.";
    sliceConfig.MemoryHigh = "24G";
    sliceConfig.MemoryMax = "25G";
  };
  systemd.services =
  {
    nix-daemon = { serviceConfig.Slice = "build.slice"; };
    hydra-evaluator = { serviceConfig.Slice = "build.slice"; };
    hydra-queue-runner =
    {
      serviceConfig.Slice = "build.slice";
      serviceConfig.LoadCredential = [ "ssh_hydra_ed25519_key:/etc/ssh/ssh_host_ed25519_key" ];
    };
  };

  system.stateVersion = "23.11";
}
