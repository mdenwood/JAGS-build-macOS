#!/bin/zsh

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
  PKG_IDENTIFIER="com.matthewdenwood.jags"
  PKG_KEYCHAIN="Developer ID: Matthew Denwood"
fi

# Create temporary folder and move postinstall script in
mkdir -p "sign/transition"
cp "build/postinstall-utils-$VERSION.sh" "sign/transition/postinstall"
chmod +x "sign/transition/postinstall"

exit 1

# Package:
pkgbuild --identifier "$PKG_IDENTIFIER" \
         --version "$VERSION" \
         --scripts "sign/transition" \
         --nopayload \
           "sign/transition-$VERSION.pkg"

# Sign and notarise standalone version:
productsign --sign "$DEVELOPER_INSTALLER" "sign/transition-$VERSION.pkg" "pkg/transition-$VERSION.pkg"
cd "pkg"
pkgutil --check-signature "transition-$VERSION.pkg"
xcrun notarytool submit "transition-$VERSION.pkg" --keychain-profile "$PKG_KEYCHAIN" --wait
xcrun stapler staple "transition-$VERSION.pkg"

# Verify:
xcrun stapler validate "transition-$VERSION.pkg"
# No code objects so not relevant:
#codesign --verify -vvvv "transition-$VERSION.pkg"
#spctl -vvv --assess --type exec "transition-$VERSION.pkg"

exit $EX_OK
