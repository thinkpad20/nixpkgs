{
  stdenv, fetchurl, xar, gzip, cpio, python, macholib,
  configd, openbsm, libobjc, libauto, zlib, openpam, bzip2,
  icu, curl, libcxx, libxml2, libxslt, sqlite, Libsystem,
  libutil, libiconv
}:

let
  # TODO: flesh this out
  frameworkSpecs = {
    Accelerate          = [];
    AppKit              = [];
    ApplicationServices = [];
    Carbon              = [];
    Cocoa               = [];
    CoreAudio           = [];
    CoreData            = [];
    CoreFoundation      = [];
    CoreServices        = [];
    Foundation          = [];
    IOKit               = [];
    Security            = [];
  };

  # I'd rather not "export" these, since they're somewhat monolithic and encourage bad habits.
  # Also, the include directory inside here should be captured (almost?) entirely by our more
  # precise Apple package structure, so with any luck it's unnecessary.
  raw = stdenv.mkDerivation rec {
    version = "10.9";
    name    = "MacOS_SDK-${version}";

    src = fetchurl {
      url    = "http://swcdn.apple.com/content/downloads/00/14/031-07556/i7hoqm3awowxdy48l34uel4qvwhdq8lgam/DevSDK_OSX109.pkg";
      sha256 = "0x6r61h78r5cxk9dbw6fnjpn6ydi4kcajvllpczx3mi52crlkm4x";
    };

    buildInputs = [ xar gzip cpio ];

    __impureHostDeps = [ "/System/Library/Frameworks" ];

    buildCommand = ''
      xar -x -f $src
      mkdir $out
      cd $out
      cat $NIX_BUILD_TOP/Payload | gzip -d | cpio -idm

      versionsPaths="$(find . -name "Versions")"

      for versionsPath in $versionsPaths; do
        local root="''${versionsPath:1}"
        cp -P "$root/Current" "$versionsPath"

        if [ -d "$versionsPath/Current/Frameworks" ]; then
          ln -s "Versions/Current/Frameworks" "$versionsPath/../Frameworks"
        fi
      done
    '';
  };

  sdk = stdenv.mkDerivation rec {
    name = "Apple-SDK-${raw.version}";

    # TODO: substitute our CoreFoundation and SystemConfiguration in
    external = [
      configd openbsm xar libobjc libauto zlib openpam bzip2 icu curl libcxx
      libxml2 libxslt sqlite Libsystem libutil libiconv

      "/usr/lib/system"
    ];
    frameworks = builtins.attrNames frameworkSpecs;

    buildInputs = [ python macholib ] ++ external;

    buildCommand = ''
      python ${./copy-closure.py} "$out" "${raw}" "$external" "$frameworks"

      mkdir -p $out/include
      cp -r ${raw}/usr/include/xpc $out/include
    '';

    # Not propagated, because we just copy the files into our store
    # (this package is super unfree and impure, unsurprisingly)
    __impureHostDeps = [
      "/usr/lib/system/libxpc.dylib"
      "/System/Library/Frameworks"
      "/System/Library/PrivateFrameworks"

      "/usr/lib/liblangid.dylib"
      "/usr/lib/libOpenScriptingUtil.dylib"
      "/usr/lib/libcsfde.dylib"
      "/usr/lib/libCoreStorage.dylib"

      # TODO: these shouldn't be necessary
      "/usr/lib/libCRFSuite.dylib"
      "/usr/lib/libcups.2.dylib"
      "/usr/lib/libbz2.1.0.dylib"

      # TODO: this is a more minimal version of libasn1.dylib from heimdal.
      # Figure out if we can just use ours or if it's meaningfully different
      "/usr/lib/libheimdal-asn1.dylib"
    ];
  };
in {
  frameworks = stdenv.lib.mapAttrs (_: _: sdk) frameworkSpecs;
}