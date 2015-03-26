{ appleDerivation, libsecurity_utilities, libsecurity_codesigning, m4, osx_private_sdk, CommonCrypto }:

appleDerivation {
  buildInputs = [ libsecurity_utilities m4 ];

  patchPhase = ''
    patch -p1 < ${./handletemplates.patch}
    unpackFile ${libsecurity_codesigning.src}
    mv libsecurity_codesigning*/lib security_codesigning
  '';

  NIX_CFLAGS_COMPILE = "-I${CommonCrypto}/include/CommonCrypto";
}
