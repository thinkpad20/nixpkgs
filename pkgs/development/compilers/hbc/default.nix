{ stdenv, fetchurl, byacc }:

stdenv.mkDerivation rec {
  version = "0.9999.4";
  name    = "hbc-${version}";

  src = fetchurl {
    url    = "ftp://ftp.mimuw.edu.pl/mirror/ftp.cs.chalmers.se/pub/haskell/chalmers/${name}.src.tar.gz";
    sha256 = "19va3a45x2k7q50gmjbaalyq7xfii7iq5wyrz0yn442p6asibddg";
  };

  buildInputs = [ byacc ];

  meta = {
    description = "The Chalmers Haskell-B Compiler";

    longDescription =
      '' The Chalmers Haskell-B compiler implements full Haskell 1.3, as well
         as some optional extensions. It is written by Lennart Augustsson and
         based on the classic LML compiler by Augustsson and Johnsson.
      '';

    license     = stdenv.lib.licenses.gpl3;
    maintainers = with stdenv.lib.maintainers; [ copumpkin ];
    platforms   = stdenv.lib.platforms.all;
  };
}
