#!/bin/zsh

# Return codes:
EX_OK=0
EX_USAGE=64
EX_CONFIG=78

# Note: this script is intended to be run from the root directory (by the Makefile)
./scripts/check_deps.sh

VERSION="$1"
WDIR=`pwd`
export SDKROOT=`readlink -f "/Library/Developer/CommandLineTools/SDKs/MacOSX11.sdk"`
export MACOSX_DEPLOYMENT_TARGET="11.0"
export CORES=12

if ! [ -f sources/cppunit-$VERSION.tar.gz ]; then
  echo "Source file not found" 2>&1
  exit $EX_CONFIG
fi

echo "\n** Building aarch64 cppunit **\n"
tar xf "sources/cppunit-$VERSION.tar.gz" -C "tmp"
cd tmp/cppunit-$VERSION
.configure --prefix=$WDIR/lib/cppunit
make -j $CORES
make install DESTDIR="$WDIR/tmp/cppunit-aarch64"
make clean

exit 0


./configure --prefix=/opt/cppunit/1.15.1
make -j 12
make install DESTDIR="$WDIR/cppunit/arm64"
make clean

arch -arch x86_64 $SHELL
WDIR=`pwd`
export SDKROOT=`readlink -f "/Library/Developer/CommandLineTools/SDKs/MacOSX11.sdk"`
export MACOSX_DEPLOYMENT_TARGET="11.0"
./configure --prefix=/opt/cppunit/1.15.1 --host=x86_64-apple-darwin20 --build=x86_64-apple-darwin20
make -j 12 
make install DESTDIR="$WDIR/cppunit/x86_64"
exit

cd cppunit
cp -r arm64 universal

IDIR="/opt/cppunit/1.15.1"
for ff in "/lib/libcppunit-1.15.1.dylib" "/lib/libcppunit.dylib" "/lib/libcppunit.a"; do
  echo $ff
  lipo "$WDIR/cppunit/universal/$IDIR/$ff" "$WDIR/cppunit/x86_64/$IDIR/$ff" -create -output "$WDIR/cppunit/universal/$IDIR/$ff"
done

cd universal
ln -s $IDIR opt/cppunit/current
mkdir -p usr/local/lib/pkgconfig
ln -s /opt/cppunit/current/lib/pkgconfig/cppunit.pc usr/local/lib/pkgconfig/cppunit.pc
tar zcf "../cppunit-universal-1.15.1.tar.gz" opt usr

cd ../
sudo tar -xvf cppunit-universal-1.15.1.tar.gz -C /
