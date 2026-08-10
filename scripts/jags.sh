#!/bin/zsh

# Abort on error:
set -e

# Return codes:
EX_OK=0
EX_USAGE=64
EX_CONFIG=78

# Note: this script is intended to be run from the root directory (by the Makefile)
./scripts/check_deps.sh

## Check arguments
if [ "$#" -ne 4 ]; then
    echo "Error: 4 arguments required (got $#)."
    echo "Usage: $0 <VERSION> <BLAS> <THREAD> <ARCH>"
    exit $EX_USAGE
fi

VERSION="$1"
BLAS="$2"
THREAD="$3"
ARCH="$4"

# Extract major version
VERSMAJ=$(echo $VERSION | cut -d "." -f 1)
if [ ! "$VERSION" -ge 4 ] 2>/dev/null; then
  echo "JAGS version 4.x.y or greater required" 1>&2
  exit $EX_USAGE
fi

# Check that the blas is valid:
if [[ "$BLAS" == "vecLib" ]]; then
  # Do nothing
elif [[ "$BLAS" == "accelerate" ]]; then
  BLAS="vecLib"
elif [[ "$BLAS" == "Accelerate" ]]; then
  BLAS="vecLib"
elif [[ "$BLAS" == "apple" ]]; then
  BLAS="vecLib"
elif [[ "$BLAS" == "refBLAS" ]]; then
  # Do nothing
elif [[ "$BLAS" == "lapack" ]]; then
  BLAS="refBLAS"
elif [[ "$BLAS" == "ref" ]]; then
  BLAS="refBLAS"
elif [[ "$BLAS" == "netlib" ]]; then
  BLAS="refBLAS"
elif [[ "$BLAS" == "Netlib" ]]; then
  BLAS="refBLAS"
else
  echo "Invalid BLAS specified" 1>&2
  exit $EX_USAGE
fi  

# Check that the multi-threading option is valid:
if [[ "$THREAD" == "gcd" ]]; then
  # Do nothing
elif [[ "$THREAD" == "GCD" ]]; then
  THREAD="gcd"
elif [[ "$THREAD" == "openmp" ]]; then
  # TODO: add OpenMP support by downloading/bundling the OpenMP run time from https://mac.r-project.org/openmp/ with jags-terminal only and compiling rjags with -fopenmp
  # Note: rjags will probably need re-compiling after switching to openmp build using jags-version ???
  echo "Compiling against OpenMP is not yet supported" 1>&2
  exit $EX_USAGE
elif [[ "$THREAD" == "single" ]]; then
  # Do nothing
elif [[ "$THREAD" == "st" ]]; then
  THREAD="single"
else
  echo "Invalid THREAD specified" 1>&2
  exit $EX_USAGE
fi  

# Check that the arch is valid:
if [[ "$ARCH" == "arm64" ]]; then
  ARCH="aarch64"
elif [[ "$ARCH" == "arm" ]]; then
  ARCH="aarch64"
elif [[ "$ARCH" == "aarch64" ]]; then
  # Do nothing
elif [[ "$ARCH" == "intel" ]]; then
  ARCH="x86_64"
elif [[ "$ARCH" == "x86_64" ]]; then
  # Do nothing
else
  echo "Invalid ARCH specified" 1>&2
  exit $EX_USAGE
fi

# If JAGS 4 then only vecLib-single-aarch64 is supported:
if [[ $VERSMAJ -eq 4 ]]; then
  if [[ "$BLAS" != "vecLib" || "$THREAD" != "single" || "$ARCH" != "aarch64" ]]; then
      echo "Compilation for JAGS 4 requires vecLib-single-aarch64" 1>&2
      exit $EX_USAGE
  fi
fi

# Detect if this is an official build:
VBSTRING="$VERSION ($BLAS-$THREAD-$ARCH build)"
DEVELOPER_EMAIL=$(security find-generic-password -s "com.apple.gke.notary.tool" -a "JAGS_PROFILE" 2>/dev/null | grep '"acct"' | cut -d'"' -f4)
if [ -z "$DEVELOPER_EMAIL" ]; then
  if [[ $($DEVELOPER_EMAIL | shasum -a 256 | awk '{print $1}') == "7da19dd0e2664a65c66298ef8c37965baee4deecf01745743b9e13c082b860b3" ]]; then
    VBSTRING="$VERSION (official $BLAS-$THREAD-$ARCH binary)"
  fi
fi

export WDIR=`pwd`
export SDKROOT=`readlink -f "/Library/Developer/CommandLineTools/SDKs/MacOSX11.sdk"`
export MACOSX_DEPLOYMENT_TARGET="11.0"
export CORES=$(sysctl -n hw.ncpu)
export PATH=" /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

if ! [ -f sources/JAGS-$VERSION.tar.gz ]; then
  echo "Source file not found" >&2
  exit $EX_CONFIG
fi

rm -rf "tmp/JAGS-$VERSION"
tar -xmf "sources/JAGS-$VERSION.tar.gz" -C "tmp"
cd "tmp/JAGS-$VERSION"

echo "\n** Compiling JAGS-$BLAS-$THREAD-$ARCH **\n"

# Change configure script to show the build:    
mv configure configure.orig
cat configure.orig | sed "s/PACKAGE_STRING=\'JAGS $VERSION\'/PACKAGE_STRING=\'JAGS $VBSTRING\'/g" | sed "s/PACKAGE_VERSION=\'$VERSION\'/PACKAGE_VERSION=\'$VBSTRING\'/g" > configure
chmod 755 configure
  
# Set up BLAS:
if [[ "$BLAS" == "vecLib" ]]; then
  
  blasstr="-framework Accelerate"
  lapkstr="-framework Accelerate"
  fflags="-O3 -static-libgfortran -static-libquadmath"
  flibs="/opt/gfortran/lib/gcc/$ARCH-apple-darwin20.0/14.2.0/libgcc.a /opt/gfortran/lib/gcc/$ARCH-apple-darwin20.0/14.2.0/libquadmath.a /opt/gfortran/lib/gcc/$ARCH-apple-darwin20.0/14.2.0/libgfortran.a"
  
elif [[ "$blas" == "refBLAS" ]]; then
  
  blasstr="$WDIR/lib/lapack/librefblas.a"
  lapkstr="$WDIR/lib/lapack/liblapack.a"
  fflags="-O2 -static-libgfortran -static-libquadmath"
  flibs="/opt/gfortran/lib/gcc/$ARCH-apple-darwin20.0/14.2.0/libgcc.a /opt/gfortran/lib/gcc/$ARCH-apple-darwin20.0/14.2.0/libquadmath.a /opt/gfortran/lib/gcc/$ARCH-apple-darwin20.0/14.2.0/libgfortran.a"
  
else
  echo "Error:  unhandled BLAS option $BLAS" 1>&2 
  exit $EX_SOFTWARE
fi

# Get configuration for cppunit:
CPPUCNF="$("$WDIR/lib/pkg-config/bin/pkg-config" --cflags "$WDIR/lib/cppunit/lib/pkgconfig/cppunit.pc") --target=$ARCH-apple-darwin20"

# Configure according to THREAD:
if [[ "$THREAD" == "single" ]]; then
  
  PATH="$WDIR/lib/pkg-config/bin/:$PATH" CPPUNIT_CFLAGS="$CPPUCNF" FC="/opt/gfortran/bin/$ARCH-apple-darwin20.0-gfortran" FCLIBS="$flibs" \
    CXXFLAGS="-O3 --target=$ARCH-apple-darwin20" F77="/opt/gfortran/bin/$ARCH-apple-darwin20.0-gfortran" FFLAGS="$fflags" FLIBS="$flibs" \
    ./configure --prefix="/opt/jags/$VERSMAJ.x-current" --with-included-ltdl --with-blas="$blasstr" --with-lapack="$lapkstr" --disable-openmp \
    > configure.out >&2
  
elif [[ "$THREAD" == "gcd" ]]; then
  
  PATH="$WDIR/lib/pkg-config/bin/:$PATH" CPPUNIT_CFLAGS="$CPPUCNF" FC="/opt/gfortran/bin/$ARCH-apple-darwin20.0-gfortran" FCLIBS="$flibs" \
    CXXFLAGS="-O3 --target=$ARCH-apple-darwin20" F77="/opt/gfortran/bin/$ARCH-apple-darwin20.0-gfortran" FFLAGS="$fflags" FLIBS="$flibs" \
    ./configure --prefix="/opt/jags/$VERSMAJ.x-current" --with-included-ltdl --with-blas="$blasstr" --with-lapack="$lapkstr" --enable-gcd \
    > configure.out >&2
  
else
  echo "Error:  unhandled THREAD option $THREAD" 1>&2 
  exit $EX_SOFTWARE
fi
   
# Only needed when cross-compiling - note that we must have x86_64 here
if [[ "$ARCH" == "x86_64" ]]; then
  sed -i '' -e 's/compiler_flags=$/compiler_flags="--target=x86_64-apple-darwin20"/' libtool
  sed -i '' -e 's/linker_flags=$/linker_flags="--target=x86_64-apple-darwin20"/' libtool
fi
  
# Remove spurious libquadmath dependency:
find . -name 'Makefile' -type f -exec sed -i '' -e 's/libquadmath.a/libgfortran.a/' {} +
find . -name 'Makefile' -type f -exec sed -i '' -e 's/-static-libquadmath//' {} +    
  
echo "\tRunning make..."
make -j $CORES > make.out >&2

echo "\tRunning make check..."
make -j $CORES check > make_check.out >&2
cat make_check.out | tail -n 17

make install DESTDIR="$WDIR/build/JAGS-$VERSION-$BLAD-$THREAD-$ARCH" > make_install.out >&2    

exit 1


./configure --prefix=$WDIR/lib/cppunit
make clean
make -j $CORES
make install DESTDIR="$WDIR/tmp/cppunit-aarch64"

echo "\n** Compiling cppunit-x86_64 **\n"
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

cd cppunit-universal
tar zcf "../cppunit-universal-$VERSION.tar.gz" .
cd ../
tar -xvf cppunit-universal-$VERSION.tar.gz -C /

exit $EX_OK

# For possible installation to /opt
#cd universal
#ln -s $IDIR opt/cppunit/current
#mkdir -p usr/local/lib/pkgconfig
#ln -s /opt/cppunit/current/lib/pkgconfig/cppunit.pc usr/local/lib/pkgconfig/cppunit.pc
#tar zcf "../cppunit-universal-1.15.1.tar.gz" opt usr
#cd ../
#sudo tar -xvf cppunit-universal-1.15.1.tar.gz -C /
