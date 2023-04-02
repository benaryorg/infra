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
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDHuaQCsI854sA1EZ0+iI/J0XoLhNcE+OeqsCDEnHKUM nixos.home.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJGWGQc44BCDR6m2LB5sThYXxHMNRwJCBi0irETLVb3p terraria.lxd.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILhgl6pXnjK5ZxzFduRmZkSbx5bsF8Tito0M2n8A+2HZ shell.cloud.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIa1t6BignThNJcZzAkhY55aWXPuzAU1KZW+O+C/r4dN lxd6.cloud.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMaVAQfp0SDxPbCj/3v1daa96z6PgA40EBLOQzQeCMUp lxd5.cloud.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBNnok7mR9DK1pMAIlae5TG1fMzTtPOQGnNfSNtRy/5m lxd4.cloud.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMWOCWu2yJ2MK7LZSrLYttRZhat6stqTjG/WQaYSEl/3 lxd3.cloud.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIACQK4kpl9p3Y4ZtpqEyvostg7zmnFpb91Z3b+gxDwGQ lxd2.cloud.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMQN8n7AM1npiKBQiyUIg1PzT06umWFcfFFXKV5XSS8R lxd1.cloud.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIXlwb9MouVvrLm49diJxeUktG/HFxS2tedjKMEaYWEi syncplay.lxd.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKqIBwvc1Pf6GbuVs8fo1UFGJLomb47VJO01ZzFv+BSK steam.lxd.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA0ia1VnkJ5lVZ2Nsk7tv+1FPFn9P1JrNRdGRYCf1eNY prometheus.lxd.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPDCg36Iu+EzJhyUNSPldV+G8q4p8l9JWPT0nbG2XXCw xmpp.lxd.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIs11y4uzabLAmdqd5Zz7owITCiNwx9Z2q5encfwz/kA nixos-builder.cloud.bsocat.net"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDRtlLH3L15UCWuEY40YsBuCr9bSr8X4Sk5omHRbl4YE turn.lxd.bsocat.net"
  ];
  keyConversion = keys: lists.foldr (a: b: a // b) {} (map (key: pipe key [ (splitString " ") reverseList (list: { "${head list}" = (pipe list [ tail reverseList (concatStringsSep " ") ]); }) ]) keys);
in
  {
    sshkey = keyConversion sshkey;
    hostkey = keyConversion hostkey;
    sshuser = "benaryorg";
  }
