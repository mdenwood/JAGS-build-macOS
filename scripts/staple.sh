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

## Check arguments
if [ "$#" -ne 1 ]; then
    echo "Error: 1 arguments required (got $#)."
    echo "Usage: $0 <PKGFILE>"
    exit $EX_USAGE
fi

BUILD="$1"
WDIR=`pwd`

echo "Fix the universal build"
echo "DONE BUT CHECK:  Use --identifier and --version with pkgbuild (https://manpagez.com/man/1/pkgbuild/) to make sure JAGS 5 does not overwrite JAGS 4, but that JAGS-5.0.1-vecLib-gcd-universal does overwrite the same 5.0.0 build"
echo "DONE BUT CHECK:  transition should allow rjags-4 from CRAN to install and run"
echo "Provide fixed-link JAGS-5.x-aarch64 and JAGS-5.x-x86_64 for automatic downloads on build machines?"
echo "Back-port configure changes from rjags 5.x to 4.x ??"
echo "Also modify rjags configure script to look under the new path for jags.pc"
exit 1





echo "FIXME"
exit 1

## Remove final signed output:
rm -rf "$WDIR/release/$BUILD.pkg"

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

# Sign and notarise standalone version:
rm -rf "sign/pkg"
mkdir -p "sign/pkg"
productsign --sign "$DEVELOPER_INSTALLER" "sign/JAGS-$BUILD.pkg" "sign/pkg/JAGS-$BUILD.pkg"
cd "sign/pkg"
pkgutil --check-signature "JAGS-$BUILD.pkg"
xcrun notarytool submit "JAGS-$BUILD.pkg" --keychain-profile "$PKG_KEYCHAIN" --wait
xcrun stapler staple "JAGS-$BUILD.pkg"

# Verify:
xcrun stapler validate "JAGS-$BUILD.pkg"
spctl -a -vv -t install "JAGS-$BUILD.pkg"

# Move to pkg directory once verification is complete:
mv "JAGS-$BUILD.pkg" "$WDIR/pkg/JAGS-$BUILD.pkg"


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
