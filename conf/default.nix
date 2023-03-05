{ lib }:
with lib;
let
  sshkey =
  [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAsXZcbbZzIjxvguXzAOM/eds9CZl5cqWJBL+ScgHliC benaryorg@gnutoo.home.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKubEmPiQTJCpFuXhubW3SDlxoBXK+sFhcHsUH6kz32p benaryorg@mir.home.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrKgj+479k+nZjVKAeVnh0clxh6MUuEmY0BTtaNMDi5 benaryorg@shell.cloud.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOwmYJYilHh3ICizwCrBHh8tUGhodC8dv73IUTJp8jP2 defaultuser@go.home.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDfpS9sdMC0lz0rDlmOxT+MA6HNbcbYqRIzYx2AD+VwX user@work"
  ];
  hostkey =
  [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJGWGQc44BCDR6m2LB5sThYXxHMNRwJCBi0irETLVb3p terraria.lxd.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILhgl6pXnjK5ZxzFduRmZkSbx5bsF8Tito0M2n8A+2HZ shell.cloud.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIa1t6BignThNJcZzAkhY55aWXPuzAU1KZW+O+C/r4dN lxd6.cloud.bsocat.net"
  ];
  keyConversion = keys: lists.foldr (a: b: a // b) {} (map (key: pipe key [ (splitString " ") reverseList (list: { "${head list}" = (pipe list [ tail reverseList (concatStringsSep " ") ]); }) ]) keys);
in
  {
    sshkey = keyConversion sshkey;
    hostkey = keyConversion hostkey;
    sshuser = "benaryorg";
  }
