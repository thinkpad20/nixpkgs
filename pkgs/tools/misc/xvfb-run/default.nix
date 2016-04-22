{ stdenv, fetchurl, makeWrapper, xkbcomp, xorgserver, getopt, xkeyboard_config, xauth, utillinux, which, fontsConf, writeText}:
let
  xvfb_run = fetchurl {
    url = https://projects.archlinux.org/svntogit/packages.git/plain/trunk/xvfb-run?h=packages/xorg-server;
    sha256 = "1f9mrhqy0l72i3674n98bqlq9a10h0rh9qfjiwvivz3hjhq5c0gz";
  };
  screenSizePatch = writeText "xvfb-run_screensize.patch" ''
    --- xvfb-run 2016-11-09 19:29:41.798000000 +0000
    +++ xvfb_run    2016-11-09 20:04:49.408000000 +0000
    @@ -16,7 +16,8 @@
     AUTHFILE=
     ERRORFILE=/dev/null
     STARTWAIT=3
    -XVFBARGS="-screen 0 640x480x8"
    +SCREEN_SIZE="''${SCREEN_SIZE:-1024x768x24}"
    +XVFBARGS="-screen 0 $SCREEN_SIZE"
     LISTENTCP="-nolisten tcp"
     XAUTHPROTO=.
  '';
in
stdenv.mkDerivation {
  name = "xvfb-run";
  buildInputs = [makeWrapper];
  buildCommand = ''
    mkdir -p $out/bin
    cp ${xvfb_run} $out/bin/xvfb-run
    cd $out/bin
    chmod +wx xvfb-run
    patch -p0 < ${screenSizePatch}
    sed -i 's|XVFBARGS="|XVFBARGS="-xkbdir ${xkeyboard_config}/etc/X11/xkb |' xvfb-run
    wrapProgram $PWD/xvfb-run \
      --set XKB_BINDIR "${xkbcomp}/bin" \
      --set FONTCONFIG_FILE "${fontsConf}" \
      --prefix PATH : ${getopt}/bin:${xorgserver.out}/bin:${xauth}/bin:${which}/bin:${utillinux}/bin
  '';
}
