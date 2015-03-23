{ appleDerivation, libsecurity_utilities, m4, osx_private_sdk, CommonCrypto }:

appleDerivation {
  buildInputs = [ libsecurity_utilities m4 ];

  patchPhase = ''
    rm -f lib/u32handleobject.cpp lib/handletemplates.cpp lib/handleobject.cpp
  '';

  NIX_CFLAGS_COMPILE = "-I${osx_private_sdk}/usr/local/include -I${CommonCrypto}/include/CommonCrypto";

  # patchPhase = ''
  #   cp ${osx_private_sdk}/usr/local/include/security_cdsa_utils/cuFileIo.h lib
  #   cp ${osx_private_sdk}/usr/local/include/security_cdsa_utils/cuPem.h lib
  #   cp ${osx_private_sdk}/usr/local/include/security_cdsa_utils/cuEnc64.h lib
  #   cp -R ${osx_private_sdk}/usr/local/include/security_codesigning lib
  #   unpackFile ${Security.src}
  #   cp Security-*/libsecurity_cdsa_utils/lib/cuPem.cpp lib

  #   substituteInPlace lib/osxverifier.cpp \
  #     --replace '<security_codesigning/reqdumper.h>' '"security_codesigning/reqdumper.h"' \
  #     --replace '<security_codesigning/requirement.h>' '"security_codesigning/requirement.h"'

  #   substituteInPlace lib/security_codesigning/reqreader.h --replace \
  #     '<security_codesigning/requirement.h>' '"requirement.h"'
  # '';

  # postInstall = ''
  #   ln -s $out/include/security_cdsa_utilities $out/include/security_cdsa_utils
  # '';
}
