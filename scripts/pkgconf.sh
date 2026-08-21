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
export SDKROOT=`readlink -f "/Library/Developer/CommandLineTools/SDKs/MacOSX11.sdk"`
export MACOSX_DEPLOYMENT_TARGET="11.0"

if ! [ -f "sources/pkgconf-$VERSION.tar.gz" ]; then
  echo "Source file not found" >&2
  exit $EX_CONFIG
fi

# Verify checksum:
if [[ "$VERSION" == "3.0.5" ]]; then
  if [[ ! $(shasum -a 256 "sources/pkgconf-$VERSION.tar.gz" | awk '{print $1}') ==  
        "245d441b9d8f7b74390e060cb9db1a326c26f1b96b1a6c3216b54a5d5439367a" ]]; then
    echo "Invalid SHA256 checksum for pkgconf version $VERSION" >&2
    exit $EX_USAGE
  fi
else
  echo "Unable to validate download: no SHA256 checksum available for pkgconf version $VERSION" >&2
  exit $EX_SOFTWARE
fi

rm -rf "tools/pkgconf-lite/"
rm -rf "tmp/pkgconf-lipo/"
mkdir -p "tmp/pkgconf-lipo/"

rm -rf tmp/pkgconf-pkgconf-$VERSION tmp/pkgconf-$VERSION
tar -xmf "sources/pkgconf-$VERSION.tar.gz" -C "tmp"
mv -f tmp/pkgconf-pkgconf-$VERSION tmp/pkgconf-$VERSION

echo "\n** Building pkgconf **\n"
cd tmp/pkgconf-$VERSION

for arch in arm64 x86_64; do
  echo "Compiling pkgconf-$arch..."

  make -f Makefile.lite clean

  make -f Makefile.lite \
    CC="clang" \
    CFLAGS="-O2 --target=${arch}-apple-darwin20" \
    LDFLAGS="-target=${arch}-apple-darwin20" \
    SYSTEM_LIBDIR="/usr/lib" \
    SYSTEM_INCLUDEDIR="/usr/include" \
    PKG_DEFAULT_PATH="/usr/lib/pkgconfig:/usr/share/pkgconfig:/opt/jags/lib/pkgconfig"

  cp pkgconf-lite "$WDIR/tmp/pkgconf-lipo/pkgconf-$arch"
done

## Make UB:
mkdir -p "$WDIR/tools/pkgconf-lite/bin"
mkdir -p "$WDIR/tools/pkgconf-lite/versions/$VERSION/bin"
mkdir -p "$WDIR/tools/pkgconf-lite/versions/$VERSION/doc/"

lipo "$WDIR/tmp/pkgconf-lipo/pkgconf-arm64" "$WDIR/tmp/pkgconf-lipo/pkgconf-x86_64" -create -output "$WDIR/tools/pkgconf-lite/versions/$VERSION/bin/pkg-config"
cp AUTHORS "$WDIR/tools/pkgconf-lite/versions/$VERSION/doc/"
cp COPYING "$WDIR/tools/pkgconf-lite/versions/$VERSION/doc/"
echo "This is pkgconf-lite version $VERSION - see https://github.com/pkgconf/pkgconf for source code\n" > "$WDIR/tools/pkgconf-lite/versions/$VERSION/doc/notes.txt"

## Just for ease of use with building JAGS:
ln -Fs "$WDIR/tools/pkgconf-lite/versions/$VERSION/bin/pkg-config" "$WDIR/tools/pkgconf-lite/bin/pkg-config"

touch "$WDIR/tools/pkgconf-lite/.stamp"
exit 0
