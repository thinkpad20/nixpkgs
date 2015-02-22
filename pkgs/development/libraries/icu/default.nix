{ stdenv, fetchurl, fixDarwinDylibNames }:

let
  pname = "icu4c";
  version = "53.1";
in
stdenv.mkDerivation {
  name = pname + "-" + version;

  src = fetchurl {
    url = "http://download.icu-project.org/files/${pname}/${version}/${pname}-"
      + (stdenv.lib.replaceChars ["."] ["_"] version) + "-src.tgz";
    sha256 = "0a4sg9w054640zncb13lhrcjqn7yg1qilwd1mczc4w60maslz9vg";
  };

  # FIXME: This fixes dylib references in the dylibs themselves, but
  # not in the programs in $out/bin.
  buildInputs = stdenv.lib.optional stdenv.isDarwin fixDarwinDylibNames;

  postUnpack = ''
    sourceRoot=''${sourceRoot}/source
    echo Source root reset to ''${sourceRoot}
  '';

  preConfigure = ''
    sed -i -e "s|/bin/sh|${stdenv.shell}|" configure
    export INSTALL='install -c'
  '';

  configureFlags = "--disable-debug CC=cc CXX=c++ SHELL=bash" +
    stdenv.lib.optionalString stdenv.isDarwin " --enable-rpath --disable-renaming ";

  # The recommendation is to prepend a define to this file, but this seems simpler
  postConfigure = stdenv.lib.optionalString stdenv.isDarwin ''
    substituteInPlace common/unicode/uconfig.h --replace "#define U_DISABLE_RENAMING 0" "#define U_DISABLE_RENAMING 1"
  '';

  # For some reason Apple provides a unified libicucore.dylib and some things expect
  # to find it, so let's provide it too
  postBuild = if stdenv.isDarwin then ''
    COMMON_OBJ=./common/*.o
    I18N_OBJ=./i18n/*.o
    IO_OBJ=./io/*.o
    STUB_DATA_OBJ=./stubdata/*.o
    DYLIB_OBJS="$COMMON_OBJ $I18N_OBJ $IO_OBJ $STUB_DATA_OBJ"

    mkdir -p $out/lib
    c++ -current_version ${version} -compatibility_version 1 -dynamiclib -dynamic \
      -Os -fno-exceptions -fvisibility=hidden -fvisibility-inlines-hidden -dead_strip \
      -install_name $out/lib/libicucore.A.dylib -o $out/lib/libicucore.A.dylib $DYLIB_OBJS
    ln -s libicucore.A.dylib $out/lib/libicucore.dylib
  '' else null;

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "Unicode and globalization support library";
    homepage = http://site.icu-project.org/;
    maintainers = with maintainers; [ raskin urkud ];
    platforms = platforms.all;
  };
}
