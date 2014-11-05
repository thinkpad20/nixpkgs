{ stdenv, writeTextFile, perl }:

writeTextFile {
  name = "patch-dyld";
  text = ''
    #${stdenv.shell}

    ${perl}/bin/perl -i -0777 -pe 's/\/nix\/store\/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-dyld-239\.4\/lib\/dyld/\/usr\/lib\/dyld\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00/sg' $1
  '';
  executable  = true;
  destination = "/bin/patch-dyld";
}