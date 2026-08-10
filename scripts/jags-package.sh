#!/bin/zsh

# Set only if not already set:
: ${XCRUN_SIGN="Developer ID Application: Matt Denwood"}
: ${PDBUILD_SIGN="Developer ID Installer: Matt Denwood"}
: ${KEYCHAIN_PROFILE="Matt Denwood"}

# Abort on error, use of unset variable, or error within pipe:
set -euo pipefail

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
elif [[ "$ARCH" == "u" ]]; then
  arch="universal"
elif [[ "$ARCH" == "biarch" ]]; then
  arch="universal"
elif [[ "$ARCH" == "fat" ]]; then
  arch="universal"
elif [[ "$ARCH" == "universal" ]]; then
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
set +e  # Temporarily disable stop-on-error
DEVELOPER_EMAIL=$(security find-generic-password -s "com.apple.gke.notary.tool" -a "JAGS_PROFILE" 2>/dev/null | grep '"acct"' | cut -d'"' -f4)
set -e
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


## Make a list of archs and dependencies for checking:
echo "Making dependency overview..."
cd "tmp/JAGS-$VERSION-$BLAS-$THREAD-$ARCH"
BINDEPFILE="$WDIR/tmp/JAGS-$VERSION-$BLAS-$THREAD-$ARCH/binary_dependencies.txt"
echo "Binary dependencies:\n" >> "$BINDEPFILE"
for dd in $(find "opt" -type d -print); do
  for ff in $(ls "$dd"); do
    ftype=$(file -I "$dd/$ff")
    # If a binary:
    if echo "$ftype" | grep -q "application/x-mach-binary"; then
      # That isn't a symlink:
      if test ! -L "$dd/$ff"; then
        ## Output dependencies, architectures and macos min versions for checking:
        echo "$ff" >> "$BINDEPFILE"
        otool -L "$dd/$ff" >> "$BINDEPFILE"
        lipo -archs "$dd/$ff" >> "$BINDEPFILE"
        otool -l "$dd/$ff" | grep -E -A4 '(LC_VERSION_MIN_MACOSX|LC_BUILD_VERSION)' | grep -B1 sdk >> "$BINDEPFILE"
        echo "" >> "$BINDEPFILE"
      fi
    fi
  done
done

## Sign binaries
for dd in $(find "opt" -type d -print); do
  for ff in $(ls "$dd"); do
    ftype=$(file -I "$dd/$ff")
    sign=0
    if echo "$ftype" | grep -q "application/x-mach-binary"; then
      sign=1
    fi
    if [[ "$ff" == "jags" ]] || [[ "$ff" == "jags-terminal" ]] || [[ "$ff" == "jags-switch" ]] || [[ "$ff" == "jags-uninstall" ]]; then
      sign=1
    fi
    if [[ -d "$dd/$ff" ]]; then
      sign=0
    fi
    if test ! -L "$dd/$ff"; then
    fi
    if [[ $sign -eq 1 ]]; then
      echo "Signing: $dd/$ff"
      xcrun codesign --force -o runtime --timestamp -s "$XCRUN_SIGN" "$dd/$ff"
    fi
  done
done

cd "$WDIR/tmp"

pkgbuild \
      --root "JAGS-$VERSION-$BLAS-$THREAD-$ARCH/opt" \
      --identifier com.mattdenwood.pkg.JAGS \
      --ownership recommended \
      --version "$VERSION" \
      --install-location /opt \
      "$WDIR/build/JAGS-$VERSION-$BLAS-$THREAD-$ARCH.pkg"

exit 0

tar zcf "$bdir/JAGS-$version-$blas-$arch.tgz" opt
  

if [[ "$ARCH" == "universal" ]]; then
  echo "Running lipo..."
  
  echo "Binary dependencies:\n" >> "$bdir/binary_dependencies.txt"
  
  mv "JAGS-$version-$blas-aarch64" "JAGS-$version-$blas-universal"
  
  
  for dd in $(find "opt" -type d -print); do
    for ff in $(ls "$dd"); do
      ftype=$(file -I "$dd/$ff")
      # If a binary:
      if echo "$ftype" | grep -q "application/x-mach-binary"; then
        # That isn't a symlink:
        if test ! -L "$dd/$ff"; then
          # Stitch together:
        	lipo "$dd/$ff" "../JAGS-$version-$blas-x86_64/$dd/$ff" -create -output "$dd/$ff"
        
          ## Output dependencies, architectures and macos min versions for checking:
          echo "$ff" >> "$bdir/binary_dependencies.txt"
          otool -L "$dd/$ff" >> "$bdir/binary_dependencies.txt"
          lipo -archs "$dd/$ff" >> "$bdir/binary_dependencies.txt"
          otool -l "$dd/$ff" | grep -E -A4 '(LC_VERSION_MIN_MACOSX|LC_BUILD_VERSION)' | grep -B1 sdk >> "$bdir/binary_dependencies.txt"
          echo "" >> "$bdir/binary_dependencies.txt"
        fi
      fi
    done
  done
  
fi

exit 1


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
  
elif [[ "$BLAS" == "refBLAS" ]]; then
  
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
  
  PKG_CONFIG="$WDIR/lib/pkg-config/bin/pkg-config" PKG_CONFIG_PATH="$WDIR/lib/cppunit/lib/pkgconfig/" \
    FC="/opt/gfortran/bin/$ARCH-apple-darwin20.0-gfortran" FCLIBS="$flibs" CFLAGS="-O3 --target=$ARCH-apple-darwin20" CXXFLAGS="-O3 --target=$ARCH-apple-darwin20" \
    F77="/opt/gfortran/bin/$ARCH-apple-darwin20.0-gfortran" FFLAGS="$fflags" FLIBS="$flibs" \
    ./configure --build="$ARCH-apple-darwin20" --prefix="/opt/jags/versions/jags/$VERSMAJ.x-current" --with-included-ltdl --with-blas="$blasstr" --with-lapack="$lapkstr" --disable-openmp \
    > configure.out >&2
  
elif [[ "$THREAD" == "gcd" ]]; then
  
  PKG_CONFIG="$WDIR/lib/pkg-config/bin/pkg-config" PKG_CONFIG_PATH="$WDIR/lib/cppunit/lib/pkgconfig/" \
    FC="/opt/gfortran/bin/$ARCH-apple-darwin20.0-gfortran" FCLIBS="$flibs" CFLAGS="-O3 --target=$ARCH-apple-darwin20" CXXFLAGS="-O3 --target=$ARCH-apple-darwin20" \
    F77="/opt/gfortran/bin/$ARCH-apple-darwin20.0-gfortran" FFLAGS="$fflags" FLIBS="$flibs" \
    ./configure --build="$ARCH-apple-darwin20" --prefix="/opt/jags/versions/jags/$VERSMAJ.x-current" --with-included-ltdl --with-blas="$blasstr" --with-lapack="$lapkstr" --enable-gcd \
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

# Make and check  
echo "\tRunning make..."
make --jobs=$CORES > make.out 2>&1

echo "\tRunning make check..."
make --jobs=$CORES check > make_check.out
cat make_check.out | tail -n 17

# Create correct directory structure:
make install DESTDIR="$WDIR/tmp/JAGS-$VERSION-$BLAS-$THREAD-$ARCH" > make_install.out
mv "$WDIR/tmp/JAGS-$VERSION-$BLAS-$THREAD-$ARCH/opt/jags/versions/jags/$VERSMAJ.x-current" "$WDIR/tmp/JAGS-$VERSION-$BLAS-$THREAD-$ARCH/opt/jags/versions/jags/$VERSION-$BLAS-$THREAD-$ARCH"
touch "$WDIR/tmp/JAGS-$VERSION-$BLAS-$THREAD-$ARCH/.stamp"

exit $EX_OK
