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
  keyConversion = keys: lists.foldr (a: b: a // b) {} (map (key: pipe key [ (splitString " ") reverseList (list: { "${head list}" = (pipe list [ tail reverseList (concatStringsSep " ") ]); }) ]) keys);
in
  {
    sshkey = keyConversion sshkey;
    sshuser = "benaryorg";
  }
