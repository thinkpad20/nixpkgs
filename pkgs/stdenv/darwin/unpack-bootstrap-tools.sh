set -e

# Unpack the bootstrap tools tarball.
echo Unpacking the bootstrap tools...
$mkdir $out
$bzip2 -d < $tarball | (cd $out && $cpio -i)

# Set the ELF interpreter / RPATH in the bootstrap binaries.
echo Patching the tools...

export PATH=$out/bin

for i in $out/bin/*; do
  if ! test -L $i; then
    echo patching $i
    install_name_tool -add_rpath $out/lib $i || true
  fi
done

for i in $out/lib/*.dylib $out/System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation; do
  if ! test -L $i; then
    echo patching $i

    id=$($otool -D "$i" | tail -n 1)
    install_name_tool -id "$(dirname $i)/$(basename $id)" $i

    libs=$($otool -L "$i" | tail -n +2 | grep -v libSystem | cat)
    if [ -n "$libs" ]; then
      install_name_tool -add_rpath $out/lib $i
    fi
  fi
done

ln -s bash $out/bin/sh
ln -s bzip2 $out/bin/bunzip2

# FIXME!
cd $out/bin
ln -s /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/dsymutil
