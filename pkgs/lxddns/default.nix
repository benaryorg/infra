{ lib, stdenv, fetchFromGitHub, nix, rustPlatform }:

rustPlatform.buildRustPackage rec
{
  pname = "lxddns";
  version = "4.0.2";

  src = fetchFromGitHub
  {
    owner = "benaryorg";
    repo = pname;
    rev = "fa659565b156a4568d8ba7bc825912a55cc1ba8b";
    sha256 = "sha256-1Fs8/U9O+95L/rIkeTgsNkvoTRVa3uNvoBI2+sQ7l7Q=";
  };

  cargoSha256 = "sha256-eNsRO5/lqisYlGTi2IOYhdS4B/7VRlvHfCUp5Owa0GE=";

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
