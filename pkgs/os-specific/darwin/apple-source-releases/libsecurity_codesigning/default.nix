{ appleDerivation, libsecurity_utilities, libsecurity_cdsa_utilities }:

appleDerivation {
  buildInputs = [ libsecurity_utilities libsecurity_cdsa_utilities ];
}
