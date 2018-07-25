{ stdenv, fetchurl, libxml2, readline, zlib, perl, cairo, gtk3, gsl
, pkgconfig, gtksourceview, pango, gettext, automake, autoconf
, makeWrapper, gsettings-desktop-schemas, hicolor-icon-theme
, gnome3, texinfo
, headless ? stdenv.isDarwin
}:

let
  # It requires this specific version of automake since it's redoing
  # automake commands on top of files which already exist.
  automake_1_15 = automake.overrideDerivation (d: rec {
    name = "automake-1.15";
    src = fetchurl {
      url = "mirror://gnu/automake/${name}.tar.xz";
      sha256 = "0dl6vfi2lzz8alnklwxzfz624b95hb1ipjvd3mk177flmddcf24r";
    };
  });
in

stdenv.mkDerivation rec {
  name = "pspp-1.0.1";

  src = fetchurl {
    url = "mirror://gnu/pspp/${name}.tar.gz";
    sha256 = "1r8smr5057993h90nx0mdnff8nxw9x546zzh6qpy4h3xblp1la5s";
  };

  # Adds the SAVE DATA COLLECTION command
  patches = [
    ./0001-New-command-SAVE-DATA-COLLECTION.patch
    ./0002-tests-Add-missing-file.patch
    ./0003-outfile-optional.patch
    ./0004-mdd-more-info.patch
  ];

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [
    libxml2 readline zlib perl cairo gsl gtksourceview pango gettext
    automake_1_15 autoconf texinfo
  ] ++ stdenv.lib.optionals (!headless) [
    gtk3 makeWrapper gsettings-desktop-schemas hicolor-icon-theme
  ];

  doCheck = false;

  enableParallelBuilding = true;

  configureFlags = stdenv.lib.optional headless "--without-gui";

  preFixup = stdenv.lib.optionalString (!headless) ''
    wrapProgram "$out/bin/psppire" \
     --prefix XDG_DATA_DIRS : "$out/share" \
     --prefix XDG_DATA_DIRS : "$XDG_ICON_DIRS" \
     --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH" \
     --prefix GIO_EXTRA_MODULES : "${stdenv.lib.getLib gnome3.dconf}/lib/gio/modules"
  '';

  meta = {
    homepage = http://www.gnu.org/software/pspp/;
    description = "A free replacement for SPSS, a program for statistical analysis of sampled data";
    license = stdenv.lib.licenses.gpl3Plus;

    longDescription = ''
      PSPP is a program for statistical analysis of sampled data. It is
      a Free replacement for the proprietary program SPSS.

      PSPP can perform descriptive statistics, T-tests, anova, linear
      and logistic regression, cluster analysis, factor analysis,
      non-parametric tests and more. Its backend is designed to perform
      its analyses as fast as possible, regardless of the size of the
      input data. You can use PSPP with its graphical interface or the
      more traditional syntax commands.
    '';

    platforms = stdenv.lib.platforms.unix;
  };
}
