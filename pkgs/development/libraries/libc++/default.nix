{ stdenv, fetchurl, fetchsvn, cmake, libcxxabi, python }:

let
  version = "3.5.0";

in stdenv.mkDerivation rec {
  name = "libc++-${version}";

  src = fetchurl {
    url = "http://llvm.org/releases/${version}/libcxx-${version}.src.tar.xz";
    sha256 = "1h5is2jd802344kddm45jcm7bra51llsiv9r34h0rrb3ba2dlic0";
  };

  NIX_SKIP_CXX = "true";

  # libc++ wants to re-export libc++abi, which is totally fine.
  # however it tries to use an absolute path for that, and since we
  # pass -lc++abi in the clang wrapper, c++abi gets linked already
  # so no need to link with it again
  preConfigure = ''
    substituteInPlace lib/CMakeLists.txt \
      --replace 'set (OSX_RE_EXPORT_LINE "/usr/lib/libc++abi.dylib ' 'set (OSX_RE_EXPORT_LINE "' \
      --replace '"''${CMAKE_OSX_SYSROOT}/usr/lib/libc++abi.dylib"' ""
  '';

  buildInputs = [ cmake libcxxabi python ];

  cmakeFlags = [ "-DCMAKE_BUILD_TYPE=Release"
                 "-DLIBCXX_LIBCXXABI_INCLUDE_PATHS=${libcxxabi}/include"
                 "-DLIBCXX_CXX_ABI=libcxxabi" ];

  enableParallelBuilding = true;

  passthru.abi = libcxxabi;

  meta = {
    homepage = http://libcxx.llvm.org/;
    description = "A new implementation of the C++ standard library, targeting C++11";
    license = "BSD";
    maintainers = stdenv.lib.maintainers.shlevy;
    platforms = stdenv.lib.platforms.unix;
  };
}
