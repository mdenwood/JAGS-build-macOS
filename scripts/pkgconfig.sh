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
export CORES=$(sysctl -n hw.ncpu)
export PATH=" /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

if ! [ -f sources/pkg-config-$VERSION.tar.gz ]; then
  echo "Source file not found" 2>&1
  exit $EX_CONFIG
fi

tar xf "sources/pkg-config-$VERSION.tar.gz" -C "tmp"
cd tmp/pkg-config-$VERSION

echo "\n** Building pkg-config **\n"
LDFLAGS="-framework CoreFoundation -framework Carbon" CFLAGS="-Wno-int-conversion" CXXFLAGS="-Wno-int-conversion" ./configure --with-internal-glib --prefix=$WDIR/lib/pkg-config --exec-prefix=$WDIR/lib/pkg-config
make clean
make -j 12
make install

exit 0