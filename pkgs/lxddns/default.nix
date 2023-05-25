{ lib, stdenv, fetchFromGitHub, nix, rustPlatform }:

rustPlatform.buildRustPackage rec
{
  pname = "lxddns";
  version = "4.0.2";

  src = fetchFromGitHub
  {
    owner = "benaryorg";
    repo = pname;
    rev = "d7215556f2676c3c918f82573bdfb6e6b3715458";
    sha256 = "sha256-OMJdfQrUNdjhTjwNhJWFVQ7RtNnXmO6boMp8OAMXzKY=";
  };

  cargoHash = "sha256-0T9p8GMJijmOkELyNrhI6RsazTrvu6QvYC6nqiuEXA0=";

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
