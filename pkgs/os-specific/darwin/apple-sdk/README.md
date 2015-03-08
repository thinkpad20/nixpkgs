# The Apple SDK bundle

Although we mostly try to build things from scratch where we have source available, there are plenty of Apple libraries and frameworks that programs use and have no (or limited) source available. Apple still publishes headers for them in its SDK, so we'd like to make proper Nix packages for them.

## Packaging difficulties

### Varying structure across OSes

My initial attempt to do this involved mirroring the framework dependency structure (sometimes headers in one framework import headers from a different one) in Nix, then extracting the headers to the proper location in the output and symlinking to the system headers.

This worked decently (still a few other issues that I'll describe below) on my 10.9 box, but started having issues on 10.10 because some system frameworks weren't there or had been rearranged.

### Infectious impurity

Just symlinking from our derivation to the system-wide framework binary seems sufficient until you realize that the framework has all sorts of binary dependencies of its own. These could be on other frameworks (which is fine if we add a sandbox exclusion for `/System/Library/{Private,}Frameworks`) or on libraries, which would require us to add a general propagated exclusion for `/usr/lib` (which would then allow all sorts of build systems to pick up impure libraries). The alternative is to add precise `__propagatedImpureHostDeps` for each of the dependent libraries of the given framework (e.g., `Security.framework` depends on `/usr/lib/libbsm.dylib` and needs an impure host dep for it). Unfortunately, those dependencies can vary across Mac OS versions, so we'd need our impure host deps to be determined dynamically too! Gross :(

### Coherence

Let's say you have the whole shebang linking properly and have resolved the first two issues. Chances are, if you're running a nontrivial Mac program that uses the system frameworks, your program will crash on startup.

This is because most things will be linked against both our home-built CoreFoundation.framework and the systemwide one (possibly indirectly via the other impure frameworks that depend on it). There's no fundamental problem with loading both CFs at once, but if you ever try (and many programs do, since they aren't aware that they're talking to different libraries) to pass a CF object from one to the other, it'll crash.

## My "solution"

We can solve the varying structure issue by only exposing a few guaranteed frameworks that are super unlikely to appear/disappear between OS versions (CoreFoundation, Foundation, Security, Cocoa, etc.)

To get around the infectious impurity, I'm copying all the framework binaries into the store (the Apple SDK is unfree anyway, so hydra won't touch it) and relinking them where possible. This is super gnarly and is limited in part by bad tooling: `install_name_tool` bails out when there's not enough room in the header, even though I'm reasonably sure there's no fundamental reason in Mach-O for it to do that. The python mach-o package that I'm using has a nicer interface than `install_name_tool` but seems to have just translated the `install_name_tool` header rewriting logic to python, so it suffers from the same limitation. As a result, I go out of my way to keep paths short to make things work.

A problem with relinking is that Apple seems to love dynamic invocation of the linker, so it'll call things like `dlopen` and `CFBundleCreate` on all sorts of static strings in the programs. The things it loads will most likely then try to load the system-wide `CoreFoundation` and give us another crash, so we need to patch those out too. You'll find some code in `copy-closure.py` doing that for Kerberos.framework (references Heimdal and GSS dynamically) and CarbonCore.framework (which references some encoding bundles).

At this point I have things linking somewhat properly on 10.9, but haven't tested it much on 10.10. The coherence problem is still fairly bad, and if you try to install `emacs24Macport` you'll see that although it produces the .app, you get a crash at startup.

I haven't done this yet, and am pretty tired of this problem, but I think the solution is just to bail (temporarily) on building CF ourselves. It has fairly minimal external dependencies of its own, so I'm thinking of taking some of my `copy-closure.py` logic and getting `CF` to just copy the system one into the store and relink it, possibly with only the open source headers.

I'd proably also do that with our IOKit and Security frameworks (which are independent of apple-sdk, but are still impure). In theory I think we might be able to build them properly someday, but for now they just have symlinks to the corresponding systemwide library. Instead of symlinks, we'd pull them into the store and relink them against our `CoreFoundation` and each other.

We also build SystemConfiguration.framework ourselves but I don't think it's a big deal if that one stays pure.


The final picture would be that we have impure build processes for CF, IOKit, Security, and the whole apple-sdk bundle (which would itself just link against our pre-existing CF/IOKit/Security/possibly SystemConfiguration frameworks). There wouldn't really need to be any `__propagatedImpureHostDeps` after that because they would be self-contained after building.


Also, I'm resurrecting some old (Haskell) code I wrote to deal with mach-o files to see if I can make a smarter `install_name_tool` that lets me rewrite with arbitrary sizes. If so, I'd probably bundle that like `patchelf` in the bootstrap tools and use it everywhere.
