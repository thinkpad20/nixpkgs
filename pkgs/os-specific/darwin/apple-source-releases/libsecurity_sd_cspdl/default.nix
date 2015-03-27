{ appleDerivation, libsecurity_cdsa_plugin, libsecurity_utilities,
libsecurity_cdsa_utilities, libsecurityd, libsecurity_cdsa_client }:

appleDerivation {
  buildInputs = [ libsecurity_cdsa_plugin libsecurity_utilities libsecurity_cdsa_utilities
  libsecurityd libsecurity_cdsa_client ];
}
