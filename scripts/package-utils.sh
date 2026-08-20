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
if [[ $(echo "$DEVELOPER_APPLICATION" | shasum -a 256 | awk '{print $1}') == "c4f28510cd982a3766355e2dffb4053834786200b2c89045d752155ed517c77f" ]]; then
  PKG_IDENTIFIER="com.matthewdenwood.jags-utils"
  PKG_KEYCHAIN="Developer ID: Matthew Denwood"
fi

## Ensure that the version passed in matches that in the utils-vers file:
PVERS="$VERSION"
source "utils/utils-vers.sh"
if [[ ! "$PVERS" == "$VERSION" ]]; then
  echo "The UTILSVERSION variable in the Makefile does not match the version in utils/utils-version.sh" 1>&2
  exit $EX_CONFIG
fi

## Remove final signed output:
rm -rf "$WDIR/pkg/utils-$VERSION.pkg"

## Create temporary folder and move all scripts (including postinstall script) in:
mkdir -p "sign/utils/scripts"
cp "build/postinstall-utils.sh" "sign/utils/scripts/postinstall"
chmod +x "sign/utils/scripts/postinstall"

BASEPTH="sign/utils/opt/jags/versions/utils/$VERSION/"

mkdir -p "$BASEPTH/bin"
cp "utils/jags-0.sh" "$BASEPTH/bin/jags-4"
sed -i '' "s/__MAJ__/4/g" "$BASEPTH/bin/jags-4"
chmod +x "$BASEPTH/bin/jags-4"
cp "utils/jags-0.sh" "$BASEPTH/bin/jags-5"
sed -i '' "s/__MAJ__/5/g" "$BASEPTH/bin/jags-5"
chmod +x "$BASEPTH/bin/jags-5"
cp "utils/jags-version.sh" "$BASEPTH/bin/jags-version"
chmod +x "$BASEPTH/bin/jags-version"
cp "utils/jags-uninstall.sh" "$BASEPTH/bin/jags-uninstall"
chmod +x "$BASEPTH/bin/jags-uninstall"

mkdir -p "$BASEPTH/share/man/man1"
for ff ("jags-4.1" "jags-5.1" "jags-uninstall.1" "jags-version.1"); do
  cp "utils/man/$ff" "$BASEPTH/share/man/man1/$ff"
done

## Sign installed shell scripts:
cd "$BASEPTH"
for dd in $(find "bin" -type d -print); do
  for ff in $(ls "$dd"); do
    echo "Signing $dd/$ff"
    xcrun codesign --force --timestamp --options runtime --sign "$DEVELOPER_APPLICATION" "$dd/$ff"
  done
done

cd "$WDIR"

## Then create pkg file:
pkgbuild --root "sign/utils/opt/" \
         --identifier "$PKG_IDENTIFIER" \
         --version "$VERSION" \
         --install-location "/opt/" \
         --scripts "sign/utils/scripts" \
         "sign/utils-$VERSION.pkg"

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
