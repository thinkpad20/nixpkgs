{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "79";
  name    = "Csu-${version}";

  src = fetchurl {
    url    = "http://opensource.apple.com/tarballs/Csu/${name}.tar.gz";
    sha256 = "1hif4dz23isgx85sgh11yg8amvp2ksvvhz3y5v07zppml7df2lnh";
  };

  postUnpack = ''
    sed -i 's/\/bin\/mkdir/mkdir/g'      $sourceRoot/Makefile
    sed -i 's/\/bin\/chmod/chmod/g'      $sourceRoot/Makefile
    sed -i 's/\/usr\/lib/\/lib/g'        $sourceRoot/Makefile
    sed -i 's/\/usr\/local\/lib/\/lib/g' $sourceRoot/Makefile
  '';

  installPhase = ''
    mkdir -p $out/lib
    export DSTROOT=$out
    make install
  '';

  meta = with stdenv.lib; {
    description = "Apple's common startup stubs for darwin";
    maintainers = with maintainers; [ copumpkin ];
    platforms   = platforms.darwin;
    license     = licenses.aspl20;
  };
}