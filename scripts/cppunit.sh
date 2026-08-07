#!/bin/zsh

# Abort on error:
set -e

# Return codes:
EX_OK=0
EX_USAGE=64
EX_CONFIG=78

# Note: this script is intended to be run from the root directory (by the Makefile)
./scripts/check_deps.sh

VERSION="$1"
export WDIR=`pwd`
export SDKROOT=`readlink -f "/Library/Developer/CommandLineTools/SDKs/MacOSX11.sdk"`
export MACOSX_DEPLOYMENT_TARGET="11.0"
export CORES=$(sysctl -n hw.ncpu)
export PATH=" /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

if ! [ -f sources/cppunit-$VERSION.tar.gz ]; then
  echo "Source file not found" 2>&1
  exit $EX_CONFIG
fi

tar xf "sources/cppunit-$VERSION.tar.gz" -C "tmp"
cd tmp/cppunit-$VERSION

echo "\n** Building aarch64 cppunit **\n"
./configure --prefix=$WDIR/lib/cppunit
make clean
make -j $CORES
make install DESTDIR="$WDIR/tmp/cppunit-aarch64"

echo "\n** Building x86_64 cppunit **\n"
./configure \
  --host=x86_64-apple-darwin \
  --build=aarch64-apple-darwin \
  --prefix=$WDIR/lib/cppunit \
  CC="clang -arch x86_64" \
  CXX="clang++ -arch x86_64"
make clean
make -j $CORES
make install DESTDIR="$WDIR/tmp/cppunit-x86_64"

echo "\n** Installing bi-arch cppunit to $WDIR/lib/cppunit **\n"

cd $WDIR/tmp
cp -r cppunit-aarch64 cppunit-universal
IDIR="$WDIR/lib/cppunit"
for ff in "/lib/libcppunit-$VERSION.dylib" "/lib/libcppunit.dylib" "/lib/libcppunit.a"; do
  echo $ff
  lipo "$WDIR/tmp/cppunit-universal/$IDIR/$ff" "$WDIR/tmp/cppunit-x86_64/$IDIR/$ff" -create -output "$WDIR/tmp/cppunit-universal/$IDIR/$ff"
done



exit 1

cd universal
ln -s $IDIR opt/cppunit/current
mkdir -p usr/local/lib/pkgconfig
ln -s /opt/cppunit/current/lib/pkgconfig/cppunit.pc usr/local/lib/pkgconfig/cppunit.pc
tar zcf "../cppunit-universal-1.15.1.tar.gz" opt usr

cd ../
sudo tar -xvf cppunit-universal-1.15.1.tar.gz -C /
