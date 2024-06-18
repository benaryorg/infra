{ nodes, config, ... }:
{
  benaryorg.ssh.hostkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJmYms5tymVbqKU/J4g/cHOe0/5sbs7febVBOvQnuJkj";

  benaryorg.prometheus.client.enable = true;

  benaryorg.git.adminkey = nodes."gnutoo.home.bsocat.net".config.benaryorg.ssh.userkey.benaryorg;
  benaryorg.git.enable = true;
  benaryorg.git.mirror =
  {
    nixpkgs = { url = "https://github.com/NixOS/nixpkgs.git"; };
    crane = { url = "https://github.com/ipetkov/crane.git"; };
    flake-compat = { url = "https://github.com/edolstra/flake-compat.git"; };
    nix-systems = { url = "https://github.com/nix-systems/default.git"; };
    nix-systems-default-linux = { url = "https://github.com/nix-systems/default-linux.git"; };
    nix-systems-x86_64-linux = { url = "https://github.com/nix-systems/x86_64-linux.git"; };
    flake-utils = { url = "https://github.com/numtide/flake-utils.git"; };
    rust-overlay = { url = "https://github.com/oxalica/rust-overlay.git"; };
    agenix = { url = "https://github.com/ryantm/agenix.git"; };
    ragenix = { url = "https://github.com/yaxitech/ragenix.git"; };
    colmena = { url = "https://github.com/zhaofengli/colmena.git"; };
    home-manager = { url = "https://github.com/nix-community/home-manager.git"; };
    nix-darwin = { url = "https://github.com/lnl7/nix-darwin.git"; };
    nix-generators = { url = "https://github.com/nix-community/nixos-generators.git"; };
    nixlib = { url = "https://github.com/nix-community/nixpkgs.lib.git"; };
    mobile-nixos = { url = "https://github.com/NixOS/mobile-nixos.git"; };
  };

  system.stateVersion = "24.05";
}
