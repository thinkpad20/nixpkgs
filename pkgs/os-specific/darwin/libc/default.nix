{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "997.90.3";
  name    = "Libc-${version}";

  src = fetchurl {
    url    = "http://opensource.apple.com/tarballs/Libc/${name}.tar.gz";
    sha256 = "1jz5bx9l4q484vn28c6n9b28psja3rpxiqbj6zwrwvlndzmq1yz5";
  };

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    export SRCROOT=$PWD
    export DSTROOT=$out
    export PUBLIC_HEADERS_FOLDER_PATH=include
    export PRIVATE_HEADERS_FOLDER_PATH=include
    bash xcodescripts/headers.sh
  '';
}