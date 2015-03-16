{ pkgs }:

with import ./lib.nix { inherit pkgs; };

self: super: {

  # Disable GHC 7.10.x core libraries.
  array = null;
  base = null;
  binary = null;
  bin-package-db = null;
  bytestring = null;
  Cabal = null;
  containers = null;
  deepseq = null;
  directory = null;
  filepath = null;
  ghc-prim = null;
  haskeline = null;
  hoopl = null;
  hpc = null;
  integer-gmp = null;
  pretty = null;
  process = null;
  rts = null;
  template-haskell = null;
  terminfo = null;
  time = null;
  transformers = null;
  unix = null;
  xhtml = null;

  # We have Cabal 1.22.x.
  # https://github.com/peti/jailbreak-cabal/pull/6
  jailbreak-cabal = super.jailbreak-cabal.override { Cabal = null; };

  # GHC 7.10.x's Haddock binary cannot generate hoogle files.
  # https://ghc.haskell.org/trac/ghc/ticket/9921
  mkDerivation = drv: super.mkDerivation (drv // { doHoogle = false; });

  # haddock: No input file(s).
  nats = dontHaddock super.nats;
  bytestring-builder = dontHaddock super.bytestring-builder;

  # These used to be core packages in GHC 7.8.x.
  old-locale = self.old-locale_1_0_0_7;
  old-time = self.old-time_1_1_0_3;

  # We have transformers 4.x
  mtl = self.mtl_2_2_1;
  transformers-compat = disableCabalFlag super.transformers-compat "three";

  # We have time 1.5
  aeson = disableCabalFlag super.aeson "old-locale";

  # Setup: At least the following dependencies are missing: base <4.8
  hspec-expectations = overrideCabal super.hspec-expectations (drv: {
    patchPhase = "sed -i -e 's|base < 4.8|base|' hspec-expectations.cabal";
  });
  utf8-string = overrideCabal super.utf8-string (drv: {
    patchPhase = "sed -i -e 's|base >= 3 && < 4.8|base|' utf8-string.cabal";
  });
  esqueleto = doJailbreak super.esqueleto;

  # bos/attoparsec#92
  attoparsec = dontCheck super.attoparsec;

  # Test suite fails with some (seemingly harmless) error.
  # https://code.google.com/p/scrapyourboilerplate/issues/detail?id=24
  syb = dontCheck super.syb;

  # Test suite has stricter version bounds
  retry = dontCheck super.retry;

  # Test suite fails with time >= 1.5
  http-date = dontCheck super.http-date;

  # Version 1.19.5 fails its test suite.
  happy = dontCheck super.happy;

  # Test suite fails in "/tokens_bytestring_unicode.g.bin".
  alex = dontCheck super.alex;

  # Test suite has graduated to hanging forever.
  lens = dontCheck super.lens;

  # Upstream was notified about the over-specified constraint on 'base'
  # but refused to do anything about it because he "doesn't want to
  # support a moving target". Go figure.
  barecheck = doJailbreak super.barecheck;
  cartel = overrideCabal super.cartel (drv: { doCheck = false; patchPhase = "sed -i -e 's|base >= .*|base|' cartel.cabal"; });

  # https://github.com/kazu-yamamoto/unix-time/issues/30
  unix-time = dontCheck super.unix-time;

  # Until the changes have been pushed to Hackage
  haskell-src-meta = appendPatch super.haskell-src-meta (pkgs.fetchpatch {
    url = "https://github.com/bmillwood/haskell-src-meta/pull/31.patch";
    sha256 = "0ij5zi2sszqns46mhfb87fzrgn5lkdv8yf9iax7cbrxb4a2j4y1w";
  });
  foldl = appendPatch super.foldl (pkgs.fetchpatch {
    url = "https://github.com/Gabriel439/Haskell-Foldl-Library/pull/30.patch";
    sha256 = "0q4gs3xkazh644ff7qn2mp2q1nq3jq71x82g7iaacxclkiv0bphx";
  });
  persistent-template = appendPatch super.persistent-template (pkgs.fetchpatch {
    url = "https://github.com/yesodweb/persistent/commit/4d34960bc421ec0aa353d69fbb3eb0c73585db97.patch";
    sha256 = "1gphl0v87y2fjwkwp6j0bnksd0d9dr4pis6aw97rij477bm5mrvw";
    stripLen = 1;
  });
  stringsearch = appendPatch super.stringsearch (pkgs.fetchpatch {
    url = "https://bitbucket.org/api/2.0/repositories/dafis/stringsearch/pullrequests/3/patch";
    sha256 = "1j2a327m3bjl8k4dipc52nlh2ilg94gdcj9hdmdq62yh2drslvgx";
  });
  conduit-combinators = appendPatch super.conduit-combinators (pkgs.fetchpatch {
    url = "https://github.com/fpco/conduit-combinators/pull/16.patch";
    sha256 = "1c9b1d3dxr820i107b6yly2g1apv6bbsg9ag26clcikca7dfz5qr";
  });
  wreq = overrideCabal super.wreq (drv: {
    patchPhase = ''
      substituteInPlace Network/Wreq/Internal/AWS.hs --replace System.Locale Data.Time.Format
      substituteInPlace Network/Wreq/Cache.hs \
        --replace System.Locale Data.Time.Format \
        --replace RecordWildCards "RecordWildCards, FlexibleContexts"
    '';
  });
  contravariant = overrideCabal super.contravariant (drv: {
    patchPhase = ''
      substituteInPlace src/Data/Functor/Contravariant/Compose.hs \
        --replace '<$>' '`fmap`'
    '';
  });
} // {
  # for now, GHC bug makes profunctors 4.4 un-compilable (9 GB+ of RAM)
  profunctors = self.callPackage
    ({ mkDerivation, base, comonad, distributive, semigroupoids, tagged
     , transformers
     }:
     mkDerivation {
       pname = "profunctors";
       version = "4.3.2";
       sha256 = "06dv9bjz2hsm32kzfqqm6z54197dfjm3wycnbbgl9pib711w484v";
       buildDepends = [
         base comonad distributive semigroupoids tagged transformers
       ];
       homepage = "http://github.com/ekmett/profunctors/";
       description = "Profunctors";
       license = stdenv.lib.licenses.bsd3;
     }) {};
}
