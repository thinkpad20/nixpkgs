{ fetchurl, stdenv }:

stdenv.mkDerivation {
  name = "unifdef-1.0";

  src = fetchurl {
    url = http://www.cs.cmu.edu/~ajw/public/dist/unifdef-1.0.tar.gz;
    sha256 = "1bcxq7qgf6r98m6l277fx6s0gn9sr4vn7f3s0r5mwx79waqk0k6i";
  };

  postUnpack = ''
    rm $sourceRoot/*.o $sourceRoot/unifdef
  '';

  patchPhase = stdenv.lib.optionalString stdenv.isDarwin ''
    substituteInPlace Makefile \
      --replace "-O2" "-O2 -Wno-return-type"
  '';

  buildPhase = ''
    make unifdef
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp unifdef $out/bin
  '';

  meta = {
    description = "useful for removing #ifdef'ed lines from a file while otherwise leaving the file alone";

  };
}
