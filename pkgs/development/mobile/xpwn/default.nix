{ stdenv, fetchurl, cmake, zlib, libpng, bzip2, libusb1, openssl }:

stdenv.mkDerivation {
  name = "xpwn-0.5.8git";

  src = fetchurl {
    url = "https://github.com/dborca/xpwn/archive/4534da88d4e8a32cdc9da9b5326e2cc482c95ef0.tar.gz";
    sha256 = "0q3kg41jk6wbcv46swsb59j077fz7dv2rx350jil3cdih7771w5c";
  };

  preConfigure = ''
    rm BUILD # otherwise `mkdir build` fails on case insensitive file systems
    sed -r -i \
      -e 's/(install.*TARGET.*DESTINATION )\.\)/\1bin)/' \
      -e 's!(install.*(FILE|DIR).*DESTINATION )([^)]*)!\1share/xpwn/\3!' \
      */CMakeLists.txt
    sed -i -e '/install/d' CMakeLists.txt
  '';

  buildInputs = [ cmake zlib libpng bzip2 libusb1 openssl ];

  cmakeFlags = [
    "-DCMAKE_OSX_DEPLOYMENT_TARGET="
  ];

  meta = with stdenv.lib; {
    homepage    = "http://planetbeing.lighthouseapp.com/projects/15246-xpwn";
    description = "Custom NOR firmware loader/IPSW generator for the iPhone";
    license     = licenses.gpl3Plus;
    platforms   = with platforms; linux ++ darwin;
  };
}
