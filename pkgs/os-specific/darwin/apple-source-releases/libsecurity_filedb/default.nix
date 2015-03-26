{ appleDerivation, libsecurity_utilities, libsecurity_cdsa_utilities,
libsecurity_cdsa_plugin, osx_private_sdk, apple_sdk }:

appleDerivation {
  buildInputs = [ libsecurity_utilities libsecurity_cdsa_utilities libsecurity_cdsa_plugin ];

  patchPhase = ''
    cp ${osx_private_sdk}/usr/local/include/sandbox_private.h .
    substituteInPlace sandbox_private.h --replace '<sandbox.h>' '"${apple_sdk.sdk}/include/sandbox.h"'
    substituteInPlace lib/AtomicFile.cpp --replace '<sandbox.h>' '"sandbox_private.h"'
  '';
}
