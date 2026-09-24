#!/bin/zsh

# SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
# SPDX-License-Identifier: Apache-2.0

# Set only if not already set:
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
if [ "$#" -ne 1 ]; then
    echo "Error: 1 arguments required (got $#)."
    echo "Usage: $0 <PKGFILE>"
    exit $EX_USAGE
fi

FILE="$1"
WDIR=`pwd`

if ! [ -f "pkg/$FILE" ]; then
  echo "$FILE not found under pkg" >&2
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
if [[ $(echo "$DEVELOPER_APPLICATION" | shasum -a 256 | awk '{print $1}') == "c4f28510cd982a3766355e2dffb4053834786200b2c89045d752155ed517c77f" ]]; then
  PKG_KEYCHAIN="Developer ID: Matthew Denwood"
fi

# Sign and notarise file:
mkdir -p "release/tmp"
productsign --sign "$DEVELOPER_INSTALLER" "pkg/$FILE" "release/tmp/$FILE"
cd release/tmp
pkgutil --check-signature "$FILE"
xcrun notarytool submit "$FILE" --keychain-profile "$PKG_KEYCHAIN" --wait
xcrun stapler staple "$FILE"

# Verify:
xcrun stapler validate "$FILE"
spctl -a -vv -t install "$FILE"

# If this succeeds then move it to release:
cd "$WDIR"
mv "release/tmp/$FILE" "release/$FILE"

echo "Build product stapled to release/$FILE"
rm -rf release/tmp

exit $EX_OK





echo "Implement main JAGS 5 installer"
echo "Include JAGS 4 with transition installer"
echo "DONE BUT CHECK:  Use --identifier and --version with pkgbuild (https://manpagez.com/man/1/pkgbuild/) to make sure JAGS 5 does not overwrite JAGS 4, but that JAGS-5.0.1-vecLib-gcd-universal does overwrite the same 5.0.0 build"
echo "Provide fixed-link JAGS-5.x-aarch64 and JAGS-5.x-x86_64 for automatic downloads on build machines?"
echo "Back-port configure changes from rjags 5.x to 4.x ??"
echo "Also modify rjags configure script to look under the new path for jags.pc"

# exit 1
