{ stdenv, ... }:

stdenv.mkDerivation {
  name = "subversion-1.7.16";
  unpackPhase = ":";
  configurePhase = ":";
  dontBuild = 1;
  installPhase = ''
    mkdir -p $out/bin
    cp ${/usr/bin/svn} $out/bin/svn
  '';
}
