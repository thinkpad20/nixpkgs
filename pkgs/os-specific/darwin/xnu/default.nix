{ stdenv, fetchurl, bootstrap_cmds }:

stdenv.mkDerivation rec {
  version = "2422.115.4";
  name    = "xnu-${version}";

  src = fetchurl {
    url    = "http://opensource.apple.com/tarballs/xnu/${name}.tar.gz";
    sha256 = "1ssw5fzvgix20bw6y13c39ib0zs7ykpig3irlwbaccpjpci5jl0s";
  };

  phases = [ "unpackPhase" "patchPhase" "installPhase" ];

  buildInputs = [ bootstrap_cmds ];

  patchPhase = ''
    substituteInPlace makedefs/MakeInc.cmd \
      --replace "/usr/bin/" "" \
      --replace "/bin/" "" \
      --replace "-Werror " ""

    substituteInPlace libkern/kxld/Makefile \
      --replace "-Werror " ""
  '';

  installPhase = ''
    # This is a bit of a hack...
    mkdir -p sdk/usr/local/libexec

    cat > sdk/usr/local/libexec/availability.pl <<EOF
      #!$SHELL
      if [ "\$1" == "--macosx" ]; then
        echo 10.0 10.1 10.2 10.3 10.4 10.5 10.6 10.7 10.8 10.9
      elif [ "\$1" == "--ios" ]; then
        echo 2.0 2.1 2.2 3.0 3.1 3.2 4.0 4.1 4.2 4.3 5.0 5.1 6.0 6.1 7.0
      fi
    EOF
    chmod +x sdk/usr/local/libexec/availability.pl

    export SDKROOT_RESOLVED=$PWD/sdk
    export HOST_SDKROOT_RESOLVED=$PWD/sdk
    export PLATFORM=MacOSX
    export SDKVERSION=10.7

    export CC=cc
    export CXX=c++
    export MIG=mig
    export MIGCOM=${bootstrap_cmds}/libexec/migcom
    export STRIP=strip
    export LIPO=lipo
    export LIBTOOL=libtool
    export NM=nm
    export UNIFDEF=unifdef
    export DSYMUTIL=dsymutil
    export CTFCONVERT=ctfconvert
    export CTFMERGE=ctfmerge
    export CTFINSERT=ctf_insert
    export NMEDIT=nmedit

    export HOST_OS_VERSION=10.7
    export HOST_CC=cc
    export HOST_FLEX=flex
    export HOST_BISON=bison
    export HOST_GM4=m4
    export HOST_CODESIGN='echo dummy_codesign'
    export HOST_CODESIGN_ALLOCATE=echo

    export DSTROOT=$out
    make installhdrs

    mv $out/usr/include $out
    rmdir $out/usr

    cp libsyscall/wrappers/gethostuuid*.h $out/include
  '';
}
