{ appleDerivation, apple_sdk, libsecurity_utilities, libsecurity_cdsa_client,
libsecurity_cdsa_utilities, libsecurityd, CF, libsecurity_asn1, libsecurity_pkcs12,
libsecurity_cdsa_utils, openssl, Security, osx_private_sdk, libsecurity_ocspd,
security_dotmac_tp }:

appleDerivation {
  buildInputs = [ libsecurity_utilities libsecurity_cdsa_client libsecurity_cdsa_utilities
  libsecurityd CF libsecurity_asn1 libsecurity_pkcs12 libsecurity_cdsa_utils openssl libsecurity_ocspd security_dotmac_tp ];

  patchPhase = ''
    substituteInPlace lib/Keychains.cpp --replace DLDbListCFPref.h DLDBListCFPref.h

    substituteInPlace lib/SecCertificate.cpp --replace '#include <Security/SecCertificatePriv.h>' ""

    cp ${osx_private_sdk}/usr/include/xpc/private.h xpc
    cp ${apple_sdk.sdk}/include/xpc/*.h xpc
    cp ${osx_private_sdk}/usr/local/include/sandbox_private.h lib/sandbox.h
  '';
}
