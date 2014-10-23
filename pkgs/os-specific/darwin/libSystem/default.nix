{ stdenv, fetchurl, bootstrap_cmds, xnu, libc, libdispatch }:

stdenv.mkDerivation rec {
  name = "libSystem";

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/lib $out/include

    # Set up our include directories
    cd ${libc}/include && find . -name '*.h' | cpio -pdm $out/include

    cd ${xnu}/include && find . -name '*.h' | cpio -pdm $out/include
    cd ${xnu}/System/Library/Frameworks/Kernel.framework/Headers && find . -name '*.h' | cpio -pdm $out/include
    cd ${xnu}/System/Library/Frameworks/Kernel.framework/PrivateHeaders && find . -name '*.h' | cpio -pdm $out/include
    cd ${xnu}/System/Library/Frameworks/System.framework/Versions/B/PrivateHeaders && find . -name '*.h' | cpio -pdm $out/include

    cd ${libdispatch}/include/dispatch && find . -name '*.h' | cpio -pdm $out/include


    # Set up the actual library link
    ln -s /usr/lib/libSystem.dylib $out/lib/libSystem.dylib

    # Set up links to pretend we work like a conventional unix (Apple's design, not mine!)
    for name in c dbm dl info m mx poll proc pthread rpcsvc; do
      ln -s libSystem.dylib $out/lib/lib$name.dylib
    done
  '';

  meta = with stdenv.lib; {
    description = "The Mac OS libc/libSystem (impure symlinks to binaries with pure headers)";
    maintainers = with maintainers; [ copumpkin ];
    platforms   = platforms.darwin;
    license     = licenses.aspl20;
  };
}
