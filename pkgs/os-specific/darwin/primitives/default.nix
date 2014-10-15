{ stdenv }:

stdenv.mkDerivation {
  name = "darwin-primitives";
  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/lib
    ln -s /usr/lib/dyld $out/lib/dyld
    ln -s /usr/lib/libSystem.dylib $out/lib/libSystem.dylib
  '';

  meta = with stdenv.lib; {
    description = "Impure primitive symlinks to the Mac OS libSystem and dyld";
    maintainers = with maintainers; [ copumpkin ];
    platforms   = platforms.darwin;
    license     = licenses.aspl20;
  };
}