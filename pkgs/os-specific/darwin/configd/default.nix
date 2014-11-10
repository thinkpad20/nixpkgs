{ stdenv, fetchurl, launchd }:

stdenv.mkDerivation rec {
  version = "596.15";
  name    = "configd-${version}";

  src = fetchurl {
    url    = "http://www.opensource.apple.com/tarballs/configd/${name}.tar.gz";
    sha256 = "01zgmbk67lwl3xg41pn2ykrs3va2drwjicbvfa49kpmwzf8saf2x";
  };

  phases = [ "unpackPhase" "installPhase" ];

  buildInputs = [ launchd ];

  installPhase = ''
    mkdir -p $out/include
    cp dnsinfo/*.h $out/include/
  '';
}
