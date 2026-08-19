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
export CORES=$(sysctl -n hw.ncpu)
export PATH=" /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

if ! [ -f sources/pkg-config-$VERSION.tar.gz ]; then
  echo "Source file not found" >&2
  exit $EX_CONFIG
fi

https://github.com/pkgconf/pkgconf/releases/download/pkgconf-3.0.5/pkgconf-3.0.5.tar.gz

export SYSTEM_LIBDIR="/usr/lib"
export SYSTEM_INCLUDEDIR="/usr/include"
export PKG_DEFAULT_PATH="/usr/lib/pkgconfig:/usr/share/pkgconfig:/opt/jags/lib/pkgconfig"

make -f Makefile.lite

make -f Makefile.list clean

make -f Makefile.lite \
  CC="clang" \
  CFLAGS="-arch x86_64 -O2" \
  LDFLAGS="-arch x86_64"

# But also with minos version etc

# Also copy COPYING and AUTHORS into the installer, and a README file or similar saying this is pkgconf-lite downloaded from https://github.com/pkgconf/pkgconf/ with a permissive license, and note the version
# Then add the pkg-config stuff to the uninstall scripts
# Then modify the autoconf.ac file in rjags to look for /opt/jags/versions/pkgconf-lite/current/bin/pkg-config - DO NOT symlonk to /opt/jags/bin

exit 1


rm -rf "tools/pkg-config/"
rm -rf "tmp/pkg-config-$VERSION"
tar -xmf "sources/pkg-config-$VERSION.tar.gz" -C "tmp"
cd tmp/pkg-config-$VERSION

echo "\n** Building pkg-config **\n"
LDFLAGS="-framework CoreFoundation -framework Carbon" CFLAGS="-Wno-int-conversion" CXXFLAGS="-Wno-int-conversion" ./configure --with-internal-glib --prefix=$WDIR/tools/pkg-config --exec-prefix=$WDIR/tools/pkg-config
make clean
make -j 12
make install

touch "$WDIR/tools/pkg-config/.stamp"

exit 0