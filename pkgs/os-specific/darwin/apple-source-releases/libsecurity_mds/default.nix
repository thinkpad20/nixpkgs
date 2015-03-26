{ appleDerivation, libsecurity_cdsa_plugin, libsecurity_cdsa_utilities, libsecurityd,
libsecurity_cdsa_client, libsecurity_utilities, libsecurity_filedb }:

appleDerivation {
  buildInputs = [ libsecurity_cdsa_plugin libsecurity_cdsa_utilities libsecurity_filedb
  libsecurity_utilities libsecurity_cdsa_client libsecurityd ];
}
