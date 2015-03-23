{ appleDerivation, apple_sdk, libsecurity_utilities, libsecurity_cdsa_client,
libsecurity_cdsa_utilities, libsecurityd, CF }:

appleDerivation {
  buildInputs = [ libsecurity_utilities libsecurity_cdsa_client libsecurity_cdsa_utilities
  libsecurityd CF ];

  patchPhase = ''
    substituteInPlace lib/Keychains.cpp --replace DLDbListCFPref.h DLDBListCFPref.h
  '';
}
