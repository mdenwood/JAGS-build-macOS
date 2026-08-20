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

echo "Also modify rjags configure script to look under the new path for jags.pc"
echo "Also fix jags-4 and jags-5 so they simply redirect to the correct build, allowing all arguments to be forwarded"
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

exit $EX_OK
