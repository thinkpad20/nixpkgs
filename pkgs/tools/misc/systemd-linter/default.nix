{ stdenv, fetchurl, rustPlatform, makeWrapper, nix }:

rustPlatform.buildRustPackage rec {
  name = "systemd-linter-${version}";
  version = "0.1.4";

  src = stdenv.mkDerivation {
    name = "${name}-with-cargo-lock";
    tarball = fetchurl {
      url = https://github.com/mackwic/systemd-linter/archive/v0.1.4.tar.gz;
      sha256= "0vj10wh57jb4nl21l8v5mjnp5n19hsvpqcfkp16vlnh0ay2mfq2n";
    };
    buildCommand = ''
      tar xf $tarball
      cp ${./Cargo.lock} systemd-linter-0.1.4/Cargo.lock
      mv systemd-linter-0.1.4 $out
    '';
  };

  depsSha256 = "10f7pkgaxwizl7kzhkry7wx1rgm9wsybwkk92myc29s7sqir2mxx";

  meta = with stdenv.lib; {
    description = "Lint systemd files";
    homepage = https://github.com/mackwic/systemd-linter;
    license = with licenses; [ mpl20 ];
    platforms = platforms.all;
  };
}
