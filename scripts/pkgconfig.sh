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
export CORES=$(sysctl -n hw.ncpu)
export PATH=" /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

if ! [ -f sources/pkg-config-$VERSION.tar.gz ]; then
  echo "Source file not found" >&2
  exit $EX_CONFIG
fi

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