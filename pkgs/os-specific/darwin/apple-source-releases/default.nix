{ stdenv, fetchurl, pkgs }:

let
  specToNix = name: sha256: import (stdenv.mkDerivation rec {
    inherit name;
    src = fetchurl {
      url = "http://opensource.apple.com/text/${stdenv.lib.replaceChars ["."] [""] name}.txt";
      inherit sha256;
    };
    buildCommand = ''
      echo "{" >> $out
      cat ${src} | tail -n +2 | sed '/^$/d' | awk '{ print "  " $1 " = \"" $2 "\";" }' >> $out
      echo "}" >> $out
    '';
  });

  releaseSpecs = stdenv.lib.mapAttrs specToNix {
    "os-x-10.10"         = "1h6pr5a5dc8mavv1bx8w332r99z4wfvn66higkicgwa30ncbmq5s";
    "os-x-10.9.5"        = "06p3a8mic8388my0z7jlcp4zgm79wbzywz4bq509ili1aw9psmq0";

    # I guess they changed the naming scheme after this...
    "mac-os-x-10.8.5"    = "1sw45w0bsnmybc3n4d91g8avcxxgb9pf8p90kjqx9fcp5yig5ywf";
    "mac-os-x-10.8.4"    = "09yj1x58i9j71s70bjmbmp075c8p8jg7953scxsq53hl7vh4ng96";
    "mac-os-x-10.7.4"    = "00b8anv1sjshjpjg8sw1f5a6asbfmpnrba76lpkvifdyn6w9vys4";
    "mac-os-x-10.6.2"    = "0139836pks1xc5xslz023rb7d41mcnyk0qhc6hvv1sssr2gsjjhv";
    "developer-tools-51" = "0zlggypxkhc0b028p935wq3nimhzx6xl53r2p4gilgicl8pjk0gk";
  };

  fetchRelease = releaseName: name: sha256: fetchurl {
    url = "http://www.opensource.apple.com/tarballs/${name}/${name}-${releaseSpecs.${releaseName}.${name}}.tar.gz";
    inherit sha256;
  };

  applePackage = release: params: namePath:
    let
      name = builtins.elemAt (stdenv.lib.splitString "/" namePath) 0;
      spec = releaseSpecs.${release};

      # This gives package names with the release version in them, not Apple's internal versioning scheme.
      # Pros:
      # - More human-friendly names
      # - Doesn't force retrieval of the version specs during nixpkgs evaluation
      # Cons:
      # - If Apple keeps a package with the same internal revision number between major releases, we still
      #   rebuild it, since its name changes.
      version = (builtins.parseDrvName release).version;

      appleDerivation = attrs: stdenv.mkDerivation ({
        inherit version;
        name = "${name}-${version}";
      } // (if attrs ? srcs then {} else {
        src = srcs.${release}.${name};
      }) // attrs);
      callPackage = pkgs.newScope (packages // pkgs.darwin // { inherit appleDerivation name version; });
    in callPackage (./. + builtins.toPath "/${namePath}") params;

  knotSet = stdenv.lib.mapAttrs (k: v: if (builtins.isFunction v) then v k else v);

  IOKitSrcs = stdenv.lib.mapAttrs (fetchRelease "os-x-10.9.5") {
    IOAudioFamily                        = "1dmrczdmbdkvnhjbv233wx4xczgpf5wjrhr83aizrwpks5avkxbr";
    IOFireWireFamily                     = "034n2v6z7lf1cx3sp3309z4sn8mkchjcrsf177iag46yzlzcjgfl";
    IOFWDVComponents                     = "1brr0yn6mxgapw3bvlhyissfksifzj2mqsvj9vmps6zwcsxjfw7m";
    IOFireWireAVC                        = "1anw8cfmwkavnrs28bzshwa3cwk4r1p3x72561zljx57d0na9164";
    IOFireWireSBP2                       = "0asik6qjhf3jjp22awsiyyd6rj02zwnx47l0afbwmxpn5bchfk60";
    IOFireWireSerialBusProtocolTransport = "09kiq907qpk94zbij1mrcfcnyyc5ncvlxavxjrj4v5braxm78lhi";
    IOGraphics                           = "1c110c9chafy5ilvnc08my9ka530aljggbn66gh3sjsg7lzck9nb";
    IOHIDFamily                          = "0nx9mzdw848y6ppcfvip3ybczd1fxkr413zhi9qhw7gnpvac5g3n";
    IONetworkingFamily                   = "10r769mqq7aiksdsvyz76xjln0lg7dj4pkg2x067ygyf9md55hlz";
    IOSerialFamily                       = "1bfkqmg7clwm23byr3iji812j7v1p6565b1ri6p78zviqxnxh7cx";
    IOStorageFamily                      = "0w5yr8ppl82anwph2zba0ppjji6ipf5x410zhcm1drzwn4bbkxrj";
    IOBDStorageFamily                    = "1rbvmh311n853j5qb6hfda94vym9wkws5w736w2r7dwbrjyppc1q";
    IOCDStorageFamily                    = "1905sxwmpxdcnm6yggklc5zimx1558ygm3ycj6b34f9h48xfxzgy";
    IODVDStorageFamily                   = "1fv82rn199mi998l41c0qpnlp3irhqp2rb7v53pxbx7cra4zx3i6";
    IOKitUser                            = "0kcbrlyxcyirvg5p95hjd9k8a01k161zg0bsfgfhkb90kh2s8x0m";
  } // {
    IOUSBFamily       = srcs."mac-os-x-10.8.5".IOUSBFamily;
    IOUSBFamily_older = srcs."mac-os-x-10.8.4".IOUSBFamily;
  };

  srcs = stdenv.lib.mapAttrs (k: stdenv.lib.mapAttrs (fetchRelease k)) {
    "os-x-10.10" = {
      libpthread = "09vwwahcvmxvx2xl0890gkp91n61dld29j73y2pa597bqkag2qpg";
    };
    "os-x-10.9.5" = {
      adv_cmds      = "174v6a4zkcm2pafzgdm6kvs48z5f911zl7k49hv7kjq6gm58w99v";
      architecture  = "05wz8wmxlqssfp29x203fwfb8pgbdjj1mpz12v508658166yzqj8";
      CF            = "1sadmxi9fsvsmdyxvg2133sdzvkzwil5fvyyidxsyk1iyfzqsvln";
      CommonCrypto  = "1azin6w7cnzl0iv8kd2qzgwcp6a45zy64y5z1i6jysjcl6xmlw2h";
      copyfile      = "15i2hw5aqx0fklvmq6avin5s00adacvzqc740vviwc2y742vrdcd";
      Csu           = "1hif4dz23isgx85sgh11yg8amvp2ksvvhz3y5v07zppml7df2lnh";
      dtrace        = "0pp5x8dgvzmg9vvg32hpy2brm17dpmbwrcr4prsmdmfvd4767wcf";
      dyld          = "07z7lyv6x0f6gllb5hymccl31zisrdhz4gqp722xcs9nhsqaqvn7";
      eap8021x      = "1ynkq8zmhgqhpkdg2syj085lzya0fz55d3423hvf9kcgpbjcd9ic";
      launchd       = "0w30hvwqq8j5n90s3qyp0fccxflvrmmjnicjri4i1vd2g196jdgj";
      libauto       = "17z27yq5d7zfkwr49r7f0vn9pxvj95884sd2k6lq6rfaz9gxqhy3";
      Libc          = "1jz5bx9l4q484vn28c6n9b28psja3rpxiqbj6zwrwvlndzmq1yz5";
      libclosure    = "083v5xhihkkajj2yvz0dwgbi0jl2qvzk22p7pqq1zp3ry85xagrx";
      libdispatch   = "1lc5033cmkwxy3r26gh9plimxshxfcbgw6i0j7mgjlnpk86iy5bk";
      libiconv      = "10q7yd35flr893nysn9i04njgks4m3gis7jivb9ra9dcb77gqdcn";
      Libinfo       = "1ix6f7xwjnq9bqgv8w27k4j64bqn1mfhh91nc7ciiv55axpdb9hq";
      Libnotify     = "164rx4za5z74s0mk9x0m1815r1m9kfal8dz3bfaw7figyjd6nqad";
      libresolv     = "028mp2smd744ryxwl8cqz4njv8h540sdw3an1yl7yxqcs04r0p4b";
      Libsystem     = "1yfj2qdrf9vrzs7p9m4wlb7zzxcrim1gw43x4lvz4qydpp5kg2rh";
      libunwind     = "0miffaa41cv0lzf8az5k1j1ng8jvqvxcr4qrlkf3xyj479arbk1b";
      mDNSResponder = "1cp87qda1s7brriv413i71yggm8yqfwv64vknrnqv24fcb8hzbmy";
      objc4         = "1jrdb6yyb5jwwj27c1r0nr2y2ihqjln8ynj61mpkvp144c1cm5bg";
      ppp           = "166xz1q7al12hm3q3drlp2r6fgdrsq3pmazjp3nsqg3vnglyh4gk";
      removefile    = "0ycvp7cnv40952a1jyhm258p6gg5xzh30x86z5gb204x80knw30y";
      Security      = "1nv0dczf67dhk17hscx52izgdcyacgyy12ag0jh6nl5hmfzsn8yy";
      xnu           = "1ssw5fzvgix20bw6y13c39ib0zs7ykpig3irlwbaccpjpci5jl0s";
    };
    "mac-os-x-10.8.5" = {
      configd     = "1gxakahk8gallf16xmhxhprdxkh3prrmzxnmxfvj0slr0939mmr2";
      Libc        = "0xsx1im52gwlmcrv4lnhhhn9dyk5ci6g27k6yvibn9vj8fzjxwcf";
      IOUSBFamily = "1znqb6frxgab9mkyv7csa08c26p9p0ip6hqb4wm9c7j85kf71f4j";
    };
    "mac-os-x-10.8.4" = {
      IOUSBFamily = "113lmpz8n6sibd27p42h8bl7a6c3myc6zngwri7gnvf8qlajzyml";
    };
    "mac-os-x-10.7.4" = {
      Libm = "02sd82ig2jvvyyfschmb4gpz6psnizri8sh6i982v341x6y4ysl7";
    };
    "mac-os-x-10.6.2" = {
      CarbonHeaders = "1zam29847cxr6y9rnl76zqmkbac53nx0szmqm9w5p469a6wzjqar";
    };
    "developer-tools-51" ={
      bootstrap_cmds  = "0xr0296jm1r3q7kbam98h85g23qlfi763z54ahj563n636kyk2wb";
      CoreOSMakefiles = "0sw3w3sjil0kvxz8y86b81sz82rcd1nijayki1a1bsnsf0hz6qbf";
    };
  };

  packages = knotSet {
    libpthread      = applePackage "os-x-10.10" {};

    adv_cmds        = applePackage "os-x-10.9.5" {};
    architecture    = applePackage "os-x-10.9.5" {};
    CF              = applePackage "os-x-10.9.5" {};
    CommonCrypto    = applePackage "os-x-10.9.5" {};
    copyfile        = applePackage "os-x-10.9.5" {};
    Csu             = applePackage "os-x-10.9.5" {};
    dtrace          = applePackage "os-x-10.9.5" {};
    dyld            = applePackage "os-x-10.9.5" {};
    eap8021x        = applePackage "os-x-10.9.5" {};
    IOKit           = applePackage "os-x-10.9.5" { inherit IOKitSrcs; };
    launchd         = applePackage "os-x-10.9.5" {};
    libauto         = applePackage "os-x-10.9.5" {};
    Libc            = applePackage "os-x-10.9.5" {};
    libclosure      = applePackage "os-x-10.9.5" {};
    libdispatch     = applePackage "os-x-10.9.5" {};
    libiconv        = applePackage "os-x-10.9.5" {};
    Libinfo         = applePackage "os-x-10.9.5" {};
    Libnotify       = applePackage "os-x-10.9.5" {};
    libresolv       = applePackage "os-x-10.9.5" {};
    Libsystem       = applePackage "os-x-10.9.5" {};
    libunwind       = applePackage "os-x-10.9.5" {};
    mDNSResponder   = applePackage "os-x-10.9.5" {};
    objc4           = applePackage "os-x-10.9.5" {};
    ppp             = applePackage "os-x-10.9.5" {};
    removefile      = applePackage "os-x-10.9.5" {};
    Security        = applePackage "os-x-10.9.5" {};
    xnu             = applePackage "os-x-10.9.5" {};

    Libc_old        = applePackage "mac-os-x-10.8.5" {} "Libc/825_40_1.nix";
    configd         = applePackage "mac-os-x-10.8.5" {};

    Libm            = applePackage "mac-os-x-10.7.4" {};

    CarbonHeaders   = applePackage "mac-os-x-10.6.2" {};

    bootstrap_cmds  = applePackage "developer-tools-51" {};
    CoreOSMakefiles = applePackage "developer-tools-51" {};
  };
in packages