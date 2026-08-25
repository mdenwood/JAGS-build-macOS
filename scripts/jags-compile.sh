#!/bin/zsh

# SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
# SPDX-License-Identifier: Apache-2.0

# Abort on error, use of unset variable, or error within pipe:
set -euo pipefail

# Return codes:
EX_OK=0
EX_USAGE=64
EX_CONFIG=78

# Note: this script is intended to be run from the root directory (by the Makefile)
./scripts/check_deps.sh
# TODO: don't run if 4.3.2 x86_64 build needed

## Check arguments
if [ "$#" -ne 2 ]; then
    echo "Error: 2 arguments required (got $#)."
    echo "Usage: $0 <VERSION> <BLAS-THREAD-[U]ARCH>"
    exit $EX_USAGE
fi

VERSION="$1"
BUILD="$2"
BUILDELEMS=( ${(s:-:)BUILD} )
BLAS=$BUILDELEMS[1]
THREAD=$BUILDELEMS[2]
ARCH=$BUILDELEMS[3]

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

# If JAGS 4 then only vecLib-single is supported:
if [[ $VERSMAJ -eq 4 ]]; then
  if [[ "$BLAS" != "vecLib" || "$THREAD" != "single" ]]; then
      echo "Compilation for JAGS 4 requires vecLib-single" 1>&2
      exit $EX_USAGE
  fi
fi

# Detect if this is an official build by finding my specific Developer ID Application string:
VBSTRING="$VERSION ($BLAS-$THREAD-$ARCH build)"
set +e  # Temporarily disable stop-on-error
DEVELOPER_APPLICATION=$(security find-identity -v -p codesigning | grep "Developer ID Application" | grep -m 1 -oE '"[^"]+"' | tr -d '"')
set -e
if [ ! -z "$DEVELOPER_APPLICATION" ]; then
  if [[ $(echo "$DEVELOPER_APPLICATION" | shasum -a 256 | awk '{print $1}') == "c4f28510cd982a3766355e2dffb4053834786200b2c89045d752155ed517c77f" ]]; then
    VBSTRING="$VERSION (official $BLAS-$THREAD-$ARCH binary)"
    echo "\n\n *** Note: building official macOS binaries *** \n\n"
  fi
fi


export WDIR=`pwd`
export SDKROOT=`readlink -f "/Library/Developer/CommandLineTools/SDKs/MacOSX11.sdk"`
export MACOSX_DEPLOYMENT_TARGET="11.0"
export CORES=$(sysctl -n hw.ncpu)
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

if ! [ -f sources/JAGS-$VERSION.tar.gz ]; then
  echo "Source file not found" >&2
  exit $EX_CONFIG
fi

# Verify checksum:
if [[ "$VERSION" == "5.0.0" ]]; then
  if [[ ! $(shasum -a 256 "sources/JAGS-$VERSION.tar.gz" | awk '{print $1}') ==  
        "64fcd4883b8a8ee907722f49366cc9f277477a0647ada61356f17568f84ffff8" ]]; then
    echo "Invalid SHA256 checksum for JAGS version $VERSION" >&2
    exit $EX_USAGE
  fi
elif [[ "$VERSION" == "4.3.2" ]]; then
  if [[ ! $(shasum -a 256 "sources/JAGS-$VERSION.tar.gz" | awk '{print $1}') ==  
        "871f556af403a7c2ce6a0f02f15cf85a572763e093d26658ebac55c4ab472fc8" ]]; then
    echo "Invalid SHA256 checksum for JAGS version $VERSION" >&2
    exit $EX_USAGE
  fi
else
  for ff in $(ls "sources"); do
    echo "$ff: $(shasum -a 256 "sources/$ff" | awk '{print $1}')"
  done
  echo "Unable to validate download: no SHA256 checksum available for JAGS version $VERSION" >&2
  exit $EX_SOFTWARE
fi

rm -rf "tmp/JAGS-$VERSION"
rm -rf "tmp/JAGS-$VERSION-$BLAS-$THREAD-$ARCH"
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
  
elif [[ "$BLAS" == "refBLAS" ]]; then
  
  blasstr="$WDIR/tools/lapack/librefblas.a"
  lapkstr="$WDIR/tools/lapack/liblapack.a"
  fflags="-O2 -static-libgfortran -static-libquadmath"
  flibs="/opt/gfortran/lib/gcc/$ARCH-apple-darwin20.0/14.2.0/libgcc.a /opt/gfortran/lib/gcc/$ARCH-apple-darwin20.0/14.2.0/libquadmath.a /opt/gfortran/lib/gcc/$ARCH-apple-darwin20.0/14.2.0/libgfortran.a"
  
else
  echo "Error:  unhandled BLAS option $BLAS" 1>&2 
  exit $EX_SOFTWARE
fi

# Get configuration for cppunit:
CPPUCNF="$("$WDIR/tools/pkgconf-lite/bin/pkg-config" --cflags "$WDIR/tools/cppunit/lib/pkgconfig/cppunit.pc") --target=$ARCH-apple-darwin20"

# Set PREFIX:
PREFIX="/opt/jags/versions/jags/current-$VERSMAJ"
# This is a nice idea but rjags stores hard paths, so it unfortunately won't switch between builds:
# PREFIX="/opt/jags/versions/jags/$VERSION-$BLAS-$THREAD-$ARCH"

# Configure according to THREAD:
if [[ "$THREAD" == "single" ]]; then
  
  PKG_CONFIG="$WDIR/tools/pkgconf-lite/bin/pkg-config" PKG_CONFIG_PATH="$WDIR/tools/cppunit/lib/pkgconfig/" \
    FC="/opt/gfortran/bin/$ARCH-apple-darwin20.0-gfortran" FCLIBS="$flibs" CFLAGS="-O3 --target=$ARCH-apple-darwin20" CXXFLAGS="-O3 --target=$ARCH-apple-darwin20" \
    F77="/opt/gfortran/bin/$ARCH-apple-darwin20.0-gfortran" FFLAGS="$fflags" FLIBS="$flibs" \
    ./configure --build="$ARCH-apple-darwin20" --prefix="$PREFIX" --with-included-ltdl --with-blas="$blasstr" --with-lapack="$lapkstr" --disable-openmp \
    > configure.out >&2
  
elif [[ "$THREAD" == "gcd" ]]; then
  
  PKG_CONFIG="$WDIR/tools/pkgconf-lite/bin/pkg-config" PKG_CONFIG_PATH="$WDIR/tools/cppunit/lib/pkgconfig/" \
    FC="/opt/gfortran/bin/$ARCH-apple-darwin20.0-gfortran" FCLIBS="$flibs" CFLAGS="-O3 --target=$ARCH-apple-darwin20" CXXFLAGS="-O3 --target=$ARCH-apple-darwin20" \
    F77="/opt/gfortran/bin/$ARCH-apple-darwin20.0-gfortran" FFLAGS="$fflags" FLIBS="$flibs" \
    ./configure --build="$ARCH-apple-darwin20" --prefix="$PREFIX" --with-included-ltdl --with-blas="$blasstr" --with-lapack="$lapkstr" --enable-gcd \
    > configure.out >&2
  
else
  echo "Error:  unhandled THREAD option $THREAD" 1>&2 
  exit $EX_SOFTWARE
fi

# Modify version.cc to display the build string after the version, as rjags uses RF_makestring on it:
sed -i '' -e "s/\"$VERSION\";/\"$VERSION ($BLAS-$THREAD-$ARCH)\";/" "src/lib/version.cc"

# Modify parser.cc to add a newline in thw welcome string:
sed -i '' -e "s/\"Welcome to \" << PACKAGE_STRING << \" on/\"Welcome to \" << PACKAGE_STRING << \"\\\\n\" << \"\ton/" "src/terminal/parser.cc"
# sed -i '' -e "s/\"Welcome to \" << PACKAGE_STRING << \" on/\"Welcome to \" << PACKAGE_STRING << \"\\\\n\" << \"on/" "src/terminal/parser.cc"

# Only needed when cross-compiling:
if [[ "$ARCH" == "x86_64" ]]; then
  sed -i '' -e 's/compiler_flags=$/compiler_flags="--target=x86_64-apple-darwin20"/' libtool
  sed -i '' -e 's/linker_flags=$/linker_flags="--target=x86_64-apple-darwin20"/' libtool
fi
  
# Remove spurious libquadmath dependency:
find . -name 'Makefile' -type f -exec sed -i '' -e 's/libquadmath.a/libgfortran.a/' {} +
find . -name 'Makefile' -type f -exec sed -i '' -e 's/-static-libquadmath//' {} +    

# Make and check  
echo "\tRunning make..."
make --jobs=$CORES > make.out 2>&1

echo "\tRunning make check..."
make --jobs=$CORES check > make_check.out
cat "make_check.out" | tail -n 17
if ! grep -q "PASS:  4" "make_check.out"; then
    echo "It seems that make check failed ('PASS:  4' not found)"  1>&2 
    exit $EX_SOFTWARE
fi

# Make install
make install DESTDIR="$WDIR/tmp/JAGS-$VERSION-$BLAS-$THREAD-$ARCH" > make_install.out

# Remove the build text from the version string:
sed -i "" -e "s|Version: $VBSTRING|Version: $VERSION|g" "$WDIR/tmp/JAGS-$VERSION-$BLAS-$THREAD-$ARCH/$PREFIX/lib/pkgconfig/jags.pc"

# If this is the official binary then update the man page:
if [ ! -z "$DEVELOPER_APPLICATION" ]; then
  if [[ $(echo "$DEVELOPER_APPLICATION" | shasum -a 256 | awk '{print $1}') == "c4f28510cd982a3766355e2dffb4053834786200b2c89045d752155ed517c77f" ]]; then
    MANFILE="$WDIR/tmp/JAGS-$VERSION-$BLAS-$THREAD-$ARCH/$PREFIX/share/man/man1/jags.1"
    cp "$WDIR/utils/man/jags.1" "$MANFILE"
    sed -i "" -e "s/VERSIONSTRING/$VERSION/g" "$MANFILE"
    sed -i "" -e "s/BLASSTRING/$BLAS/g" "$MANFILE"
    sed -i "" -e "s/THREADSTRING/$THREAD/g" "$MANFILE"
    sed -i "" -e "s/ARCHSTRING/$ARCH/g" "$MANFILE"
  fi
fi

# Create correct directory structure:
mv "$WDIR/tmp/JAGS-$VERSION-$BLAS-$THREAD-$ARCH/opt/jags/versions/jags/current-$VERSMAJ" "$WDIR/tmp/JAGS-$VERSION-$BLAS-$THREAD-$ARCH/opt/jags/versions/jags/$VERSION-$BLAS-$THREAD-$ARCH"

# Finished:
touch "$WDIR/tmp/JAGS-$VERSION-$BLAS-$THREAD-$ARCH/.stamp"
exit $EX_OK
