# Infrastructure

This repository contains information necessary to keep infrastructure up and running.

Note: all of this is highly opinionated.

The primary content is the [*flake*](./flake.nix) ([Flake Documentation](https://nixos.wiki/wiki/Flakes)) and the contained [Colmena](https://github.com/zhaofengli/colmena) configuration.
The flake in turn uses the [*spec/* directory](spec/) as a source of imports/modules.
If any custom packages are required they are stored in [*pkgs/*](pkgs/) and secrets are managed in the [*secret/* tree](secret/).
Global configuration used by several parts of this is stored in [*conf/*](conf/), these include SSH keys mostly.

Additionally there are a few snippets to be found in the [*snippet/* directory](snippet/), these include minimal bootstrap configuration to use for installing a fresh server to enable *Colmena* to run against the host.

# Deployment

Deployment is designed to run on the jumphost (*shell.cloud.bsocat.net*) and from there deploy via SSH onto the hosts themselves.
The jumphost therefore is specially secured (encrypted SSH keys and sudo requiring a password) while all the others only allow access from that machine.
All communication between nodes is directly end-to-end encrypted (using *stunnel* as a last resort) and all nodes are IPv6 native.
Exceptions to the IPv6-only rule are only made when interaction with other systems is strictly required (outgoing SMTP for instance).

To avoid having to enter the jumphost SSH keys a bazillion times during deployment while *also* preventing unauthenticated access to the SSH connections use the following command:

```bash
# use temporary ssh-agent instance to apply to @default set (everything but the jumphost)
ssh-agent zsh -c 'ssh-add && exec $*' -s colmena apply --on @default
# deploy to the jumphost locally via sudo
colmena apply-local --node shell.cloud.bsocat.net --sudo
```

