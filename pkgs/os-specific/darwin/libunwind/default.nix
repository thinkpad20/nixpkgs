{ stdenv, fetchurl, dyld }:

stdenv.mkDerivation rec {
  version = "35.3";
  name    = "libunwind-${version}";

  src = fetchurl {
    url    = "http://opensource.apple.com/tarballs/libunwind/${name}.tar.gz";
    sha256 = "0miffaa41cv0lzf8az5k1j1ng8jvqvxcr4qrlkf3xyj479arbk1b";
  };

  phases = [ "unpackPhase" "buildPhase" "installPhase" ];

  buildInputs = [ dyld ];

  buildPhase = ''
    cd src
    cc -c libuwind.cxx
    cc -c Registers.s
    cc -c unw_getcontext.s
    cc -c UnwindLevel1.c
    cc -c UnwindLevel1-gcc-ext.c
    cc -c Unwind-sjlj.c
  '';

  installPhase = ''
    echo HELLO
  '';

  meta = with stdenv.lib; {
    maintainers = with maintainers; [ copumpkin ];
    platforms   = platforms.darwin;
    license     = licenses.aspl20;
  };
}
