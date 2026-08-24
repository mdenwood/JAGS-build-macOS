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
  PKG_IDENTIFIER="com.matthewdenwood"
  PKG_KEYCHAIN="Developer ID: Matthew Denwood"
fi

## Ensure that the version passed in matches that in the utils-vers file:
PVERS="$VERSION"
source "utils/utils-vers.sh"
if [[ ! "$PVERS" == "$VERSION" ]]; then
  echo "The UTILSVERSION variable in the Makefile does not match the version in utils/utils-version.sh" 1>&2
  exit $EX_CONFIG
fi

## Find the relevant pkgconf-lite (PKGCONF_VERSION is set in utils-vers.sh):
if ! [ -d "tools/pkgconf-lite/$PKGCONF_VERSION" ]; then
  echo "tools/pkgconf-lite/$PKGCONF_VERSION not found" >&2
  exit $EX_CONFIG
fi

## Remove final signed output:
rm -rf "$WDIR/pkg/utils-$VERSION.pkg"
rm -rf "sign/utils"

## Create temporary folder and move all scripts (including postinstall script) in:
mkdir -p "sign/utils/scripts"
cp "build/postinstall-utils.sh" "sign/utils/scripts/postinstall"
chmod +x "sign/utils/scripts/postinstall"

mkdir -p "sign/utils/opt/jags/versions/pkgconf-lite"
cp -r "tools/pkgconf-lite/$PKGCONF_VERSION" "sign/utils/opt/jags/versions/pkgconf-lite/$PKGCONF_VERSION"

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
for ff ("jags.1" "jags-uninstall.1" "jags-version.1"); do
  cp "utils/man/$ff" "$BASEPTH/share/man/man1/$ff"
done
for vv ("4" "5"); do
  cp "utils/man/jags-0.1" "$BASEPTH/share/man/man1/jags-$vv.1"
  sed -i '' "s/\[JAGSMAJVERS\]/${vv}/g" "$BASEPTH/share/man/man1/jags-$vv.1"
done

## Sign installed pkgconf-lite:
cd "$WDIR/sign/utils/opt/jags/versions/pkgconf-lite/$PKGCONF_VERSION/bin"
echo "Signing pkg-config"
xcrun codesign --force --timestamp --options runtime --sign "$DEVELOPER_APPLICATION" pkg-config

## Sign installed shell scripts:
cd "$WDIR/$BASEPTH"
for dd in $(find "bin" -type d -print); do
  for ff in $(ls "$dd"); do
    echo "Signing $dd/$ff"
    xcrun codesign --force --timestamp --options runtime --sign "$DEVELOPER_APPLICATION" "$dd/$ff"
  done
done

cd "$WDIR"

## Then create pkg file:
pkgbuild --root "sign/utils/opt/" \
         --identifier "$PKG_IDENTIFIER.jags-utils" \
         --version "$VERSION" \
         --install-location "/opt/" \
         --scripts "sign/utils/scripts" \
         "pkg/utils-$VERSION.pkg"


exit $EX_OK
