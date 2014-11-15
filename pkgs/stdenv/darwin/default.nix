{ system      ? builtins.currentSystem
, allPackages ? import ../../top-level/all-packages.nix
, platform    ? null
, config      ? {}
}:

let
  fetch = { file, sha256 }: import <nix/fetchurl.nix> {
    url = "https://dl.dropboxusercontent.com/u/361503/${file}";
    inherit sha256;
    executable = true;
  };

  bootstrapFiles = {
    sh = fetch {
      file = "sh";
      sha256 = "15s9daz0qjxz0n19wbc9aq4g5fcppq1lcfg7naja35cn9xrvykd5";
    };

    bzip2 = fetch {
      file = "bzip2";
      sha256 = "0gsfn285smk3v8ypb2gxnyc45k2mj5sr3vb7byxkkhqdz80gf3ww";
    };

    mkdir = fetch {
      file = "mkdir";
      sha256 = "1952sd9hf6wz6vsbmxj2q1ifzprixf8ipnlhbanc18j7l3iw4wvj";
    };

    cpio = fetch {
      file = "cpio";
      sha256 = "0pwbv8bb77z7sfps9isx6bm8rwdx9bqbyzyj40mw1qnk1w8gbgf0";
    };
  };
in rec {
  allPackages = import ../../top-level/all-packages.nix;

  commonPreHook = ''
    export NIX_ENFORCE_PURITY=1
    export NIX_IGNORE_LD_THROUGH_GCC=1
    export NIX_DONT_SET_RPATH=1
    export NIX_NO_SELF_RPATH=1
    stripAllFlags=" " # the Darwin "strip" command doesn't know "-s"
    xargsFlags=" "
    export MACOSX_DEPLOYMENT_TARGET=
    export SDKROOT=
    export CMAKE_OSX_ARCHITECTURES=x86_64
    export NIX_CFLAGS_COMPILE+=" --sysroot=/var/empty -Wno-multichar -Wno-deprecated-declarations"
  '';

  bootstrapTools = derivation {
    name = "bootstrap-tools";

    builder = bootstrapFiles.sh;

    args = [ ./unpack-bootstrap-tools.sh ];

    tarball = import <nix/fetchurl.nix> {
      url    = "https://www.dropbox.com/s/38l9q6pm4udszvj/bootstrap-tools.cpio.bz2";
      sha256 = "0sw2xbyzx49jmah41l2xgfq74f9ianbpq1bx8afbadn55qz7fp0a";
    };

    inherit system;

    mkdir = bootstrapFiles.mkdir;
    bzip2 = bootstrapFiles.bzip2;
    cpio  = bootstrapFiles.cpio;

    # FIXME: this is unnecessarily impure but I haven't done the work yet to build it
    otool = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/otool";

    langC  = true;
    langCC = true;
  };

  bootstrapPreHook = ''
    export NIX_CFLAGS_COMPILE+=" -idirafter ${bootstrapTools}/include-libSystem -F${bootstrapTools}/System/Library/Frameworks"
    export NIX_LDFLAGS_BEFORE+=" -L${bootstrapTools}/lib/"
    export LD_DYLD_PATH=${bootstrapTools}/lib/dyld
  '';

  stageFun = {cc, extraAttrs ? {}, overrides ? (pkgs: {}), extraPath ? [], extraPreHook ? ""}:
    let
      thisStdenv = import ../generic {
        inherit system config;
        name = "stdenv-darwin-boot";
        preHook =
          ''
            # Don't patch #!/interpreter because it leads to retained
            # dependencies on the bootstrapTools in the final stdenv.
            dontPatchShebangs=1
            ${commonPreHook}
            ${extraPreHook}
          '';
        shell = "${bootstrapTools}/bin/sh";
        initialPath = [bootstrapTools] ++ extraPath;
        fetchurlBoot = import ../../build-support/fetchurl {
          stdenv = stage0.stdenv;
          curl = bootstrapTools;
        };
        inherit cc;
        # Having the proper 'platform' in all the stdenvs allows getting proper
        # linuxHeaders for example.
        extraAttrs = extraAttrs // { inherit platform; };
        overrides = pkgs: (overrides pkgs) // { fetchurl = thisStdenv.fetchurlBoot; };
      };

      thisPkgs = allPackages {
        inherit system platform;
        bootStdenv = thisStdenv;
      };
    in { stdenv = thisStdenv; pkgs = thisPkgs; };

  stage0 = stageFun {
    cc = "/no-such-path";
  };

  stage1 = stageFun {
    cc = import ../../build-support/clang-wrapper {
      nativeTools  = true;
      nativePrefix = bootstrapTools;
      nativeLibc   = true;
      stdenv       = stage0.stdenv;
      libcxx       = bootstrapTools;
      shell        = "${bootstrapTools}/bin/bash";
      clang        = {
        name    = "clang-9.9.9";
        gcc     = "";
        outPath = bootstrapTools;
      };
    } // { libc = bootstrapTools; };

    extraPreHook = bootstrapPreHook;
  };

  stage2 = stageFun {
    inherit (stage1.stdenv) cc;
    extraPath    = [ stage1.pkgs.xz ];
    extraPreHook = bootstrapPreHook;
  };

  stage3 = with stage2; stageFun {
    # TODO: just make pkgs.clang do this right
    cc = import ../../build-support/clang-wrapper {
      inherit stdenv;
      nativeTools  = false;
      nativeLibc   = true;
      inherit (pkgs) libcxx coreutils;
      inherit (pkgs.llvmPackages) clang;
      binutils  = pkgs.darwin.cctools;
      shell     = "${pkgs.bash}/bin/bash";
    } // { libc = pkgs.darwin.libSystem; };

    extraPath    = [ pkgs.xz ];
    extraPreHook = ''
      export NIX_CFLAGS_COMPILE+=" -idirafter ${pkgs.darwin.libSystem}/include -F${pkgs.darwin.corefoundation}/System/Library/Frameworks"
      export NIX_LDFLAGS_BEFORE+=" -L${pkgs.darwin.libSystem}/lib/"
      export LD_DYLD_PATH=${pkgs.darwin.dyld}/lib/dyld
    '';
  };

  stage4 = with stage3; import ../generic rec {
    inherit system config;

    preHook = ''
      ${commonPreHook}
      export NIX_CFLAGS_COMPILE+=" -idirafter ${pkgs.darwin.libSystem}/include -F${pkgs.darwin.corefoundation}/System/Library/Frameworks"
      export NIX_LDFLAGS_BEFORE+=" -L${pkgs.darwin.libSystem}/lib/"
      export LD_DYLD_PATH=${pkgs.darwin.dyld}/lib/dyld
    '';

    initialPath = import ../common-path.nix { inherit pkgs; };

    shell = "${pkgs.bash}/bin/bash";

    cc = import ../../build-support/clang-wrapper {
      inherit stdenv;
      nativeTools  = false;
      nativeLibc   = true;
      inherit (pkgs) libcxx coreutils;
      inherit (pkgs.llvmPackages) clang;
      binutils  = pkgs.darwin.cctools;
      shell     = "${pkgs.bash}/bin/bash";
    } // { libc = pkgs.darwin.libSystem; };

    inherit (stdenv) fetchurlBoot;

    extraAttrs = {
      inherit platform bootstrapTools;
      libc         = pkgs.darwin.libSystem;
      shellPackage = pkgs.bash;
    };

    overrides = pkgs: {
      clang = cc;
      inherit (pkgs)
        gzip bzip2 xz bash binutils coreutils diffutils findutils gawk
        glibc gnumake gnused gnutar gnugrep gnupatch patchelf
        attr acl paxctl zlib;
    };
  };

  stdenvDarwin = stage4;
}
