#!/bin/zsh

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

if ! [ -f sources/LAPACK-$VERSION.tar.gz ]; then
  echo "Source file not found" >&2
  exit $EX_CONFIG
fi

rm -rf "tools/lapack/"
rm -rf "tmp/lapack-$VERSION"
tar -xmf "sources/LAPACK-$VERSION.tar.gz" -C "tmp"
cd "tmp/lapack-$VERSION"

for arch in aarch64 x86_64; do
  echo "Compiling lapack-$arch..."

  cp "make.inc.example" "make.inc"
  sed -i '' -e "s/FC = gfortran$/FC = \/opt\/gfortran\/bin\/$arch-apple-darwin20.0-gfortran/" make.inc
  sed -i '' -e "s/CFLAGS = -O3$/CFLAGS = -O3 --target=$arch-apple-darwin20/" make.inc
    
  make clean
  make -j $CORES blaslib
  make -j $CORES lapacklib
  rm make.inc

  mv "librefblas.a" "../librefblas-$arch.a"
  mv "liblapack.a" "../liblapack-$arch.a"

done

cd "$WDIR/tmp"
mkdir -p "$WDIR/tools/lapack/"
lipo "librefblas-aarch64.a" "librefblas-x86_64.a" -create -output "$WDIR/tools/lapack/librefblas.a"
lipo "liblapack-aarch64.a" "liblapack-x86_64.a" -create -output "$WDIR/tools/lapack/liblapack.a"

touch "$WDIR/tools/lapack/.stamp"

exit $EX_OK


# # For possible installation to /opt
# mkdir -p "opt/lapack/$lapackvers/lib/"
# ln -s "/opt/lapack/$lapackvers/" "opt/lapack/current"
# lipo "$bdir/librefblas-aarch64.a" "$bdir/librefblas-x86_64.a" -create -output "$bdir/lapack-$lapackvers/opt/lapack/$lapackvers/lib/librefblas.a"
# lipo "$bdir/liblapack-aarch64.a" "$bdir/liblapack-x86_64.a" -create -output "$bdir/lapack-$lapackvers/opt/lapack/$lapackvers/lib/liblapack.a"
# tar -zcf "../lapack-$lapackvers.tgz" opt
# cd "../"
# # Copy artefacts and clean up:
# cd "$wd"
# cp "$bdir/cppunit-$cppunitvers.tgz" "cppunit-$cppunitvers.tgz"
# cp "$bdir/lapack-$lapackvers.tgz" "lapack-$lapackvers.tgz"
# rm -r "$bdir"
# if [ $install -eq 1 ]; then
#   sudo -v -p "Enter password to proceed with sudo: "
#   sudo tar -xmf "cppunit-$cppunitvers.tgz" -C /
#   sudo tar -xmf "lapack-$lapackvers.tgz" -C /
#   echo "Build and installation complete"
# else
#   echo "Build complete - run the following commands to install:\nsudo tar -xvf cppunit-$cppunitvers.tgz -C /\nsudo tar -xvf lapack-$lapackvers.tgz -C /"
# fi
