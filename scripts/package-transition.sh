#!/bin/zsh

# SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
# SPDX-License-Identifier: Apache-2.0

# Set only if not already set:
: ${PKG_IDENTIFIER="unknown"}
: ${PKG_KEYCHAIN="INSERT KEYCHAIN PROFILE NAME HERE"}

# Abort on error, use of unset variable, or error within pipe:
set -euo pipefail

# Return codes:
EX_OK=0
EX_USAGE=64
EX_CONFIG=78

## Check arguments
if [ "$#" -ne 1 ]; then
    echo "Error: 1 arguments required (got $#)."
    echo "Usage: $0 <VERSION>"
    exit $EX_USAGE
fi

VERSION="$1"
WDIR=`pwd`

## Extract developer identity:
set +e  # Temporarily disable stop-on-error
DEVELOPER_INSTALLER=$(security find-identity -v | grep "Developer ID Installer" | grep -m 1 -oE '"[^"]+"' | tr -d '"')
set -e
if [ -z "$DEVELOPER_INSTALLER" ]; then
  echo "Unable to find a Developer ID Installer signing certificate in your Keychain" 1>&2
  exit $EX_CONFIG
fi

## Set PKG_IDENTIFIER if the developer identity matches:
if [[ $(echo "$DEVELOPER_INSTALLER" | shasum -a 256 | awk '{print $1}') == "bcf85e972ad33f433c3e117043f0c18f9718392e1becb7a08621285e64e0d3da" ]]; then
  PKG_IDENTIFIER="com.matthewdenwood.jags-transition"
  PKG_KEYCHAIN="Developer ID: Matthew Denwood"
fi

## Remove final signed output:
rm -rf "$WDIR/pkg/transition-$VERSION.pkg"

# Create temporary folder and move postinstall script in
mkdir -p "sign/transition/scripts"
cp "build/postinstall-transition-$VERSION.sh" "sign/transition/scripts/postinstall"
chmod +x "sign/transition/scripts/postinstall"

# Package:
pkgbuild --identifier "$PKG_IDENTIFIER" \
         --version "$VERSION" \
         --scripts "sign/transition/scripts" \
         --nopayload \
           "sign/transition-$VERSION.pkg"

# Sign and notarise standalone version:
rm -rf "sign/pkg"
mkdir -p "sign/pkg"
productsign --sign "$DEVELOPER_INSTALLER" "sign/transition-$VERSION.pkg" "sign/pkg/transition-$VERSION.pkg"
cd "sign/pkg"
pkgutil --check-signature "transition-$VERSION.pkg"
xcrun notarytool submit "transition-$VERSION.pkg" --keychain-profile "$PKG_KEYCHAIN" --wait
xcrun stapler staple "transition-$VERSION.pkg"

# Verify:
xcrun stapler validate "transition-$VERSION.pkg"
spctl -a -vv -t install "transition-$VERSION.pkg"

# Move to pkg directory once verification is complete:
mv "transition-$VERSION.pkg" "$WDIR/pkg/transition-$VERSION.pkg"

exit $EX_OK
