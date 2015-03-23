{ appleDerivation }:

appleDerivation {
  postInstall = ''
    ln -s $out/include/securityd $out/include/securityd_client
  '';
}
