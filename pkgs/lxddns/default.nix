{ lib, stdenv, fetchFromGitHub, nix, rustPlatform }:

rustPlatform.buildRustPackage rec
{
  pname = "lxddns";
  version = "4.0.2";

  src = fetchFromGitHub
  {
    owner = "benaryorg";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-Lxsh+lsD/5bcU1tLiabYO2JhMdLSO2Az3yTaic6pPdk=";
  };

  cargoHash = "sha256-PYLZLJPUmYl43a9NSKqzm+xJI+2B5MqD4O/qxHKVX/Q=";

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
    license = [ licenses.isc ];
  };
}
