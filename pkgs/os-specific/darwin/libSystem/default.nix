{ stdenv, fetchurl, bootstrap_cmds, xnu, libc, libm, libdispatch, cctools, libinfo, dyld, csu, architecture, libclosure }:

stdenv.mkDerivation rec {
  name = "libSystem";

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/lib $out/include

    # Set up our include directories
    cd ${xnu}/include && find . -name '*.h' | cpio -pdm $out/include
    cp ${xnu}/System/Library/Frameworks/Kernel.framework/Versions/A/Headers/Availability*.h $out/include

    cd ${libc}/include && find . -name '*.h' | cpio -pdm $out/include
    cd ${libm}/include && find . -name '*.h' | cpio -pdm $out/include
    cd ${libdispatch}/include/dispatch && find . -name '*.h' | cpio -pdm $out/include
    cd ${libinfo}/include && find . -name '*.h' | cpio -pdm $out/include
    cd ${dyld}/include && find . -name '*.h' | cpio -pdm $out/include
    cd ${architecture}/include && find . -name '*.h' | cpio -pdm $out/include
    cd ${libclosure}/include && find . -name '*.h' | cpio -pdm $out/include

    cd ${cctools}/include/mach-o && find . -name '*.h' | cpio -pdm $out/include/mach-o

    cat <<EOF > $out/include/TargetConditionals.h
    #ifndef __TARGETCONDITIONALS__
    #define __TARGETCONDITIONALS__
    #define TARGET_OS_MAC           1
    #define TARGET_OS_WIN32         0
    #define TARGET_OS_UNIX          0
    #define TARGET_OS_EMBEDDED      0
    #define TARGET_OS_IPHONE        0
    #define TARGET_IPHONE_SIMULATOR 0
    #define TARGET_OS_LINUX         0
    #endif  /* __TARGETCONDITIONALS__ */
    EOF



    # The startup object files
    cp ${csu}/lib/* $out/lib

    # Set up the actual library link
    ln -s /usr/lib/libSystem.dylib $out/lib/libSystem.dylib

    # Set up links to pretend we work like a conventional unix (Apple's design, not mine!)
    for name in c dbm dl info m mx poll proc pthread rpcsvc gcc_s.10.4 gcc_s.10.5; do
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
