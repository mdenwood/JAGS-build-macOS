#!/bin/zsh

# SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
# SPDX-License-Identifier: Apache-2.0

# Set only if not already set:
: ${PKG_IDENTIFIER="com.unknown"}
: ${PKG_KEYCHAIN="INSERT KEYCHAIN PROFILE NAME HERE"}

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
    echo "Usage: $0 <VERSION> <ARCH> <TRANSVERSION> <UTILSVERSION>"
    exit $EX_USAGE
fi

VERSION="$1"
ARCH="$2"
TRANSVERSION="$3"
UTILSVERSION="$4"
WDIR=`pwd`


## Check pkg files are available:
if ! [ -f "pkg/JAGS-$VERSION-refBLAS-single-$ARCH.pkg" ]; then
  echo "One or more JAGS .pkg file not found" >&2
  exit $EX_CONFIG
fi
if ! [ -f "pkg/JAGS-$VERSION-vecLib-single-$ARCH.pkg" ]; then
  echo "One or more JAGS .pkg file not found" >&2
  exit $EX_CONFIG
fi
if ! [ -f "pkg/JAGS-$VERSION-vecLib-gcd-$ARCH.pkg" ]; then
  echo "One or more JAGS .pkg file not found" >&2
  exit $EX_CONFIG
fi
if ! [ -f "pkg/transition-$TRANSVERSION.pkg" ]; then
  echo "Transition .pkg file not found" >&2
  exit $EX_CONFIG
fi
if ! [ -f "pkg/utils-$UTILSVERSION.pkg" ]; then
  echo "Utils .pkg file not found" >&2
  exit $EX_CONFIG
fi


## Extract developer identity:
set +e  # Temporarily disable stop-on-error
DEVELOPER_APPLICATION=$(security find-identity -v -p codesigning | grep "Developer ID Application" | grep -m 1 -oE '"[^"]+"' | tr -d '"')
DEVELOPER_INSTALLER=$(security find-identity -v | grep "Developer ID Installer" | grep -m 1 -oE '"[^"]+"' | tr -d '"')
set -e
if [ -z "$DEVELOPER_APPLICATION" ]; then
  echo "Unable to find a Developer ID Application signing certificate in your Keychain" 1>&2
  exit $EX_CONFIG
fi
if [ -z "$DEVELOPER_INSTALLER" ]; then
  echo "Unable to find a Developer ID Installer signing certificate in your Keychain" 1>&2
  exit $EX_CONFIG
fi

## Set PKG_IDENTIFIER if the developer identity matches:
if [[ $(echo "$DEVELOPER_INSTALLER" | shasum -a 256 | awk '{print $1}') == "bcf85e972ad33f433c3e117043f0c18f9718392e1becb7a08621285e64e0d3da" ]]; then
  PKG_IDENTIFIER="com.matthewdenwood"
  PKG_KEYCHAIN="Developer ID: Matthew Denwood"
fi

## Remove final signed output:
rm -rf "pkg/JAGS-$VERSION-$ARCH.pkg"


## Make installer to pkg
productbuild --distribution "build/Distribution.xml" --package-path "./pkg" --resources "./build" "pkg/JAGS-$VERSION-$ARCH.pkg"

exit 1

# Then staple everything from pkg to release


echo "Implement main JAGS 5 installer"
echo "Include JAGS 4 with transition installer"
echo "DONE BUT CHECK:  Use --identifier and --version with pkgbuild (https://manpagez.com/man/1/pkgbuild/) to make sure JAGS 5 does not overwrite JAGS 4, but that JAGS-5.0.1-vecLib-gcd-universal does overwrite the same 5.0.0 build"
echo "Provide fixed-link JAGS-5.x-aarch64 and JAGS-5.x-x86_64 for automatic downloads on build machines?"
echo "Back-port configure changes from rjags 5.x to 4.x ??"
echo "Also modify rjags configure script to look under the new path for jags.pc"

# exit 1





# Sign and notarise standalone version:
rm -rf "sign/pkg"
mkdir -p "sign/pkg"
productsign --sign "$DEVELOPER_INSTALLER" "pkg/JAGS-$VERSION-$ARCH.pkg" "sign/pkg/JAGS-$VERSION-$ARCH.pkg"
cd "sign/pkg"
pkgutil --check-signature "JAGS-$VERSION-$ARCH.pkg"
xcrun notarytool submit "JAGS-$VERSION-$ARCH.pkg" --keychain-profile "$PKG_KEYCHAIN" --wait
xcrun stapler staple "JAGS-$VERSION-$ARCH.pkg"




# Verify:
xcrun stapler validate "JAGS-$VERSION-$ARCH.pkg"
spctl -a -vv -t install "JAGS-$VERSION-$ARCH.pkg"

# Move to pkg directory once verification is complete:
mv "JAGS-$VERSION-$ARCH.pkg" "$WDIR/release/JAGS-$VERSION-$ARCH.pkg"

exit 1


# Sign and notarise standalone version:
rm -rf "sign/pkg"
mkdir -p "sign/pkg"
productsign --sign "$DEVELOPER_INSTALLER" "sign/utils-$VERSION.pkg" "sign/pkg/utils-$VERSION.pkg"
cd "sign/pkg"
pkgutil --check-signature "utils-$VERSION.pkg"
xcrun notarytool submit "utils-$VERSION.pkg" --keychain-profile "$PKG_KEYCHAIN" --wait
xcrun stapler staple "utils-$VERSION.pkg"

# Verify:
xcrun stapler validate "utils-$VERSION.pkg"
spctl -a -vv -t install "utils-$VERSION.pkg"

# Move to pkg directory once verification is complete:
mv "utils-$VERSION.pkg" "$WDIR/pkg/utils-$VERSION.pkg"
rm -rf "sign/pkg"

exit $EX_OK
