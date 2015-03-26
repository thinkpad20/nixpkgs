{ stdenv, appleDerivation, osx_private_sdk, libauto, libobjc, IOKit, sqlite, apple_sdk }:

appleDerivation {
  buildInputs = [ libauto libobjc IOKit sqlite apple_sdk.frameworks.PCSC ];
  patchPhase = ''
    substituteInPlace lib/errors.h --replace \
      '<CoreServices/../Frameworks/CarbonCore.framework/Headers/MacTypes.h>' \
      '"MacTypes.h"'
    substituteInPlace lib/debugging.cpp --replace PATH_MAX 1024
    substituteInPlace lib/vproc++.cpp --replace /usr/local/include/vproc_priv.h ${stdenv.libc}/include/vproc_priv.h
    substituteInPlace lib/superblob.h --replace 'result->at' 'result->template at'
    substituteInPlace lib/ccaudit.cpp --replace '<bsm/libbsm.h>' '"bsm/libbsm.h"'

    cp ${osx_private_sdk}/usr/include/security_utilities/utilities_dtrace.h lib
    cp ${osx_private_sdk}/usr/include/security_utilities/osxcode.h lib
    cp -R ${osx_private_sdk}/usr/local/include/bsm lib
  '';
}
