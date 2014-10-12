{ stdenv, fetchurl, autoconf, automake, libtool
, llvm, libcxx, clang, openssl, libuuid
}:

let
  baseParams = rec {
    name = "cctools-port-${version}";
    version = "845";

    src = fetchurl {
      url = "https://github.com/tpoechtrager/cctools-port/archive/"
          + "cctools-${version}-ld64-136-1.tar.gz";
      sha256 = "06pg6h1g8avgx4j6cfykdpggf490li796gzhhyqn27jsagli307i";
    };

    buildInputs = [
      autoconf automake libtool llvm clang openssl libuuid
    ];

    patches = [ ./ld-rpath-nonfinal.patch ./ld-ignore-rpath-link.patch ];

    enableParallelBuilding = true;

    configureFlags = [ "CXXFLAGS=-I${libcxx}/include/c++/v1" ];

    postPatch = ''
      patchShebangs tools
      sed -i -e 's/which/type -P/' tools/*.sh
      sed -i -e 's|clang++|& -I${libcxx}/include/c++/v1|' cctools/autogen.sh

      # Workaround for https://www.sourceware.org/bugzilla/show_bug.cgi?id=11157
      cat > cctools/include/unistd.h <<EOF
      #ifdef __block
      #  undef __block
      #  include_next "unistd.h"
      #  define __block __attribute__((__blocks__(byref)))
      #else
      #  include_next "unistd.h"
      #endif
      EOF
    '';

    preConfigure = ''
      cd cctools
      sh autogen.sh
    '';

    meta = {
      homepage = "http://www.opensource.apple.com/source/cctools/";
      description = "Mac OS X Compiler Tools (cross-platform port)";
      license = stdenv.lib.licenses.apsl20;
    };
  };
in {
  # Hacks that for the darwin stdenv (sad that we need write workarounds for what started as a darwin package)
  native = stdenv.mkDerivation (baseParams // {
    patches = baseParams.patches ++ [ ./darwin.patch ];

    postInstall = ''
      for tool in $out/bin/*; do
        /usr/bin/install_name_tool -add_rpath ${llvm}/lib $tool
      done
      for tool in $out/libexec/*/*/*; do
        /usr/bin/install_name_tool -add_rpath ${llvm}/lib $tool
      done
      cd $out/bin
      for tool in dwarfdump dsymutil; do
        ln -s /usr/bin/$tool
      done
    '';
  });

  cross =
    { cross, maloader, makeWrapper, xctoolchain}: stdenv.mkDerivation (baseParams // {
      configureFlags = baseParams.configureFlags ++ [ "--target=${cross.config}" ];

      postInstall = ''
        for tool in dyldinfo dwarfdump dsymutil; do
          ${makeWrapper}/bin/makeWrapper "${maloader}/bin/ld-mac" "$out/bin/${cross.config}-$tool" \
            --add-flags "${xctoolchain}/bin/$tool"
          ln -s "$out/bin/${cross.config}-$tool" "$out/bin/$tool"
        done
      '';
    });
}
