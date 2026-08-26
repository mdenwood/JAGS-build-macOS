#!/bin/zsh

# SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
# SPDX-License-Identifier: Apache-2.0

# Abort on error:
set -e

# Return codes:
EX_OK=0
EX_USAGE=64
EX_SOFTWARE=70
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

for f

# Verify checksum:
if [[ "$VERSION" == "0.29.2" ]]; then
  if [[ ! $(shasum -a 256 "sources/pkg-config-$VERSION.tar.gz" | awk '{print $1}') ==  
        "6fc69c01688c9458a57eb9a1664c9aba372ccda420a02bf4429fe610e7e7d591" ]]; then
    echo "Invalid SHA256 checksum for pkg-config version $VERSION" >&2
    exit $EX_USAGE
  fi
else
  for ff in $(ls "sources"); do
    echo "$ff: $(shasum -a 256 "sources/$ff" | awk '{print $1}')"
  done  
  echo "Unable to validate download: no SHA256 checksum available for pkg-config version $VERSION" >&2
  exit $EX_SOFTWARE
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