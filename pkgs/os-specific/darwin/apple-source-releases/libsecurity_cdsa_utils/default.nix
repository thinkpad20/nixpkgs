{ appleDerivation, osx_private_sdk, Security, libsecurity_utilities,
libsecurity_cdsa_utilities, apple_sdk, m4, cppcheck }:

appleDerivation {
  buildInputs = [ libsecurity_utilities libsecurity_cdsa_utilities m4 ];

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
