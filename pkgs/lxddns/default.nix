{ lib, stdenv, fetchgit, nix, rustPlatform }:

rustPlatform.buildRustPackage rec
{
  pname = "lxddns";
  version = "4.0.2";

  src = fetchgit
  {
    url = "https://git.shell.bsocat.net/lxddns.git";
    rev = "9ff9afc0eefcffcdfe052b650b7c9a88226fc3f2";
    sha256 = "sha256-upFxJ7rQBQkzfXs0ADI1omEkRU4pNtggVjYnSgIeOB4=";
  };

  cargoSha256 = "sha256-nGAxVcy5xDVZZaS/rYQ98PocBnOIouuviv5ERp4yUhA=";

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
