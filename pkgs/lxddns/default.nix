{ lib, stdenv, fetchgit, nix, rustPlatform }:

rustPlatform.buildRustPackage rec
{
  pname = "lxddns";
  version = "4.1.1";

  src = fetchgit
  {
    url = "https://git.shell.bsocat.net/lxddns.git";
    rev = "e5152ada0ff80c3a5a015710f263f4401d34d83f";
    sha256 = "sha256-mq1/KGLmIDPSqDBOMr0b7QH6f7c1feng4CQTebnDkHI=";
  };

  cargoSha256 = "sha256-etXtkUYdPGYmHDjjvkJylzz+WK7WD/KsgDw/rLu1KUE=";

  buildNoDefaultFeatures = true;
  buildFeatures = [ "http" ];

  auditable = true; # TODO: remove when this is the default

  passthru =
  {
    tests =
    {
      inherit nix;
    };
  };

  meta = with lib;
  {
    description = "Couple LXD, PowerDNS, and lxddns for public IPv6 DNS resolution for your containers.";
    homepage = "https://github.com/benaryorg/lxddns";
    changelog = "https://github.com/benaryorg/lxddns/commits/main";
    license = [ licenses.agpl3 ];
  };
}
