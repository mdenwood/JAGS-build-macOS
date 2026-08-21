#!/bin/zsh

# SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
# SPDX-License-Identifier: Apache-2.0

# Abort on error:
set -e

# Return codes:
EX_OK=0
EX_USAGE=64
EX_CONFIG=78

# Note: this script is intended to be run from the root directory (by the Makefile)
./scripts/check_deps.sh

if [ "$#" -ne 1 ]; then
    echo "Error: 1 arguments required (got $#)."
    echo "Usage: $0 <VERSION>"
    exit $EX_USAGE
fi
VERSION="$1"

export WDIR=`pwd`
export SDKROOT=`readlink -f "/Library/Developer/CommandLineTools/SDKs/MacOSX11.sdk"`
export MACOSX_DEPLOYMENT_TARGET="11.0"
export CORES=$(sysctl -n hw.ncpu)
export PATH=" /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

if ! [ -f sources/cppunit-$VERSION.tar.gz ]; then
  echo "Source file not found" >&2
  exit $EX_CONFIG
fi

# Verify checksum:
if [[ "$VERSION" == "1.15.1" ]]; then
  if [[ ! $(shasum -a 256 "sources/cppunit-$VERSION.tar.gz" | awk '{print $1}') ==  
        "89c5c6665337f56fd2db36bc3805a5619709d51fb136e51937072f63fcc717a7" ]]; then
    echo "Invalid SHA256 checksum for cppunit version $VERSION" >&2
    exit $EX_USAGE
  fi
else
  for ff in $(ls "sources"); do
    echo "$ff: $(shasum -a 256 "sources/$ff" | awk '{print $1}')"
  done
  echo "Unable to validate download: no SHA256 checksum available for cppunit version $VERSION" >&2
  exit $EX_SOFTWARE
fi

rm -rf tmp/cppunit-aarch64
rm -rf tmp/cppunit-x86_64
rm -rf tmp/cppunit-universal
rm -rf tools/cppunit
tar -xmf "sources/cppunit-$VERSION.tar.gz" -C "tmp"
cd tmp/cppunit-$VERSION

echo "\n** Compiling cppunit-aarch64 **\n"
./configure --prefix=$WDIR/tools/cppunit
make clean
make -j $CORES
make install DESTDIR="$WDIR/tmp/cppunit-aarch64"

echo "\n** Compiling cppunit-x86_64 **\n"
./configure \
  --host=x86_64-apple-darwin \
  --build=aarch64-apple-darwin \
  --prefix=$WDIR/tools/cppunit \
  CC="clang -arch x86_64" \
  CXX="clang++ -arch x86_64"
make clean
make -j $CORES
make install DESTDIR="$WDIR/tmp/cppunit-x86_64"

echo "\n** Installing bi-arch cppunit to $WDIR/tools/cppunit **\n"

cd $WDIR/tmp
cp -r cppunit-aarch64 cppunit-universal
IDIR="$WDIR/tools/cppunit"
for ff in "/lib/libcppunit-$VERSION.dylib" "/lib/libcppunit.dylib" "/lib/libcppunit.a"; do
  echo $ff
  lipo "$WDIR/tmp/cppunit-universal/$IDIR/$ff" "$WDIR/tmp/cppunit-x86_64/$IDIR/$ff" -create -output "$WDIR/tmp/cppunit-universal/$IDIR/$ff"
done

cd cppunit-universal
tar -zcf "../cppunit-universal-$VERSION.tar.gz" .
cd ../
tar -xmf cppunit-universal-$VERSION.tar.gz -C /

touch "$WDIR/tools/cppunit/.stamp"

exit $EX_OK

# For possible installation to /opt
#cd universal
#ln -s $IDIR opt/cppunit/current
#mkdir -p usr/local/lib/pkgconfig
#ln -s /opt/cppunit/current/lib/pkgconfig/cppunit.pc usr/local/lib/pkgconfig/cppunit.pc
#tar zcf "../cppunit-universal-1.15.1.tar.gz" opt usr
#cd ../
#sudo tar -xvf cppunit-universal-1.15.1.tar.gz -C /
