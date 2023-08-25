{ lib, stdenv, fetchgit, nix, rustPlatform }:

rustPlatform.buildRustPackage rec
{
  pname = "lxddns";
  version = "4.0.2";

  src = fetchgit
  {
    url = "https://git.shell.bsocat.net/lxddns.git";
    rev = "554d5a9fcd28a4d9161950ffa58cdae4a731f4c4";
    sha256 = "sha256-phIPejlAIoo3yRIuHwX72trgaIniEHhMWZtxx8fBV4g=";
  };

  cargoSha256 = "sha256-7lVWXCYBQk6pEnMeeaPySjmgughAjM5BAYa+I75m+B4=";

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
