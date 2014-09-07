{ stdenv, fetchurl, fetchsvn, cmake, libcxxabi, python }:

let
  version = "3.5.0";

in stdenv.mkDerivation rec {
  name = "libc++-${version}";

  src = fetchurl {
    url = "http://llvm.org/releases/${version}/libcxx-${version}.src.tar.xz";
    sha256 = "1h5is2jd802344kddm45jcm7bra51llsiv9r34h0rrb3ba2dlic0";
  };

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
