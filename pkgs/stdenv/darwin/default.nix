{ system      ? builtins.currentSystem
, allPackages ? import ../../top-level/all-packages.nix
, platform    ? null
, config      ? {}
}:

rec {
  allPackages = import ../../top-level/all-packages.nix;

  bootstrapTools = derivation {
    inherit system;

    name    = "trivial-bootstrap-tools";
    builder = "/bin/sh";
    args    = [ ./trivialBootstrap.sh ];

    mkdir   = "/bin/mkdir";
    ln      = "/bin/ln";
  };

  stage0 = rec {
    stdenv = import ../generic {
      inherit system config;
      name         = "stdenv-darwin-boot";
      shell        = "/bin/bash";
      initialPath  = [bootstrapTools];
      fetchurlBoot = import ../../build-support/fetchurl {
        inherit stdenv;
        curl = bootstrapTools;
      };
      gcc = "/no-such-path";
    };
  };

  fetchadc = import ../../build-support/fetchadc {
    stdenv = stage0.stdenv;
    curl   = bootstrapTools;
    adc_user = if config ? adc_user
      then config.adc_user
      else throw "You need an adc_user attribute in your config to download files from Apple Developer Connection";
    adc_pass = if config ? adc_pass
      then config.adc_pass
      else throw "You need an adc_pass attribute in your config to download files from Apple Developer Connection";
  };

  buildTools = (import ../../os-specific/darwin/command-line-tools {
    inherit fetchadc;
    stdenv = stage0.stdenv;
    xar    = bootstrapTools;
    gzip   = bootstrapTools;
    cpio   = bootstrapTools;
  }).impure;

  preHook = ''
    export NIX_ENFORCE_PURITY=
    export NIX_IGNORE_LD_THROUGH_GCC=1
    export NIX_DONT_SET_RPATH=1
    export NIX_NO_SELF_RPATH=1
    dontFixLibtool=1
    stripAllFlags=" " # the Darwin "strip" command doesn't know "-s"
    xargsFlags=" "
    export MACOSX_DEPLOYMENT_TARGET=10.6
    export SDKROOT=
    export SDKROOT_X=${buildTools.sdk}
    export NIX_CFLAGS_COMPILE+=" --sysroot=/var/empty -idirafter $SDKROOT_X/usr/include -F$SDKROOT_X/System/Library/Frameworks -Wno-multichar -Wno-#deprecated-declarations"
    export NIX_LDFLAGS_AFTER+=" -L$SDKROOT_X/usr/lib"
  '';

  stage1 = rec {
    stdenv = import ../generic {
      inherit system config preHook;
      inherit (stage0.stdenv) name shell initialPath fetchurlBoot;

      gcc = import ../../build-support/clang-wrapper {
        nativeTools  = true;
        nativePrefix = "${buildTools.tools}/Library/Developer/CommandLineTools/usr";
        nativeLibc   = true;
        stdenv       = stage0.stdenv;
        libcxx       = "/";
        shell        = "/bin/bash";
        clang        = {
          name    = "clang-9.9.9";
          gcc     = "/no-such-path";
          outPath = "${buildTools.tools}/Library/Developer/CommandLineTools/usr";
        };
      };
    };
    pkgs = allPackages {
      inherit system platform;
      bootStdenv = stdenv;
    };
  };

  stage2 = import ../generic {
    name = "stdenv-darwin";

    inherit system config preHook;
    inherit (stage1.stdenv) fetchurlBoot;

    initialPath = (import ../common-path.nix) { pkgs = stage1.pkgs; };

    gcc = import ../../build-support/clang-wrapper {
      stdenv       = stage1.stdenv;
      nativeTools  = false;
      nativeLibc   = true;
      libcxx       = stage1.pkgs.libcxx.override {
        libcxxabi = stage1.pkgs.libcxxabi.override {
          libunwind = stage1.pkgs.libunwindNative;
        };
      };
      binutils  = import ../../build-support/native-darwin-cctools-wrapper { stdenv = stage1.stdenv; };
      clang     = stage1.pkgs.clang;
      coreutils = stage1.pkgs.coreutils;
      shell     = "${stage1.pkgs.bash}/bin/bash";
    };

    shell = "${stage1.pkgs.bash}/bin/bash";
  };

  stdenvDarwin = stage2;
}
