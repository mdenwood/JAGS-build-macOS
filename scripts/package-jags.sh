#!/bin/zsh

# SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
# SPDX-License-Identifier: Apache-2.0

# Set only if not already set:
: ${PKG_IDENTIFIER="com.unknown"}

# Abort on error, use of unset variable, or error within pipe:
set -euo pipefail

# Return codes:
EX_OK=0
EX_USAGE=64
EX_SOFTWARE=70
EX_CONFIG=78

# Note: this script is intended to be run from the root directory (by the Makefile)
./scripts/check_deps.sh

## Check arguments
if [ "$#" -ne 1 ]; then
    echo "Error: 1 arguments required (got $#)."
    echo "Usage: $0 <VERSION-BLAS-THREAD-ARCH>"
    exit $EX_USAGE
fi

BUILD="$1"
WDIR=`pwd`

## Extract the vbuild (build without minor version):
VERSMAJ=$(echo $BUILD | cut -d "." -f 1)
BPARTS=("${(s:-:)BUILD}")
if [[ ! ${#BPARTS} -eq 4 ]]; then
  echo "Unexpected size of BUILD string" >&2
  exit $EX_SOFTWARE
fi
VERSION=${BPARTS[1]}
VBUILD=$(echo "$VERSMAJ-${BPARTS[2]}-${BPARTS[3]}-${BPARTS[4]}")

## Remove final signed output:
rm -rf "$WDIR/pkg/JAGS-$BUILD.pkg"

## Untar into the sign directory:
rm -rf "sign/JAGS-$BUILD"
mkdir -p "sign/JAGS-$BUILD"
tar -xf "tgz/JAGS-$BUILD.tgz" -C "sign/JAGS-$BUILD"

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

## Ensure the text string is "official" if needed:
if [[ $(echo "$DEVELOPER_APPLICATION" | shasum -a 256 | awk '{print $1}') == "c4f28510cd982a3766355e2dffb4053834786200b2c89045d752155ed517c77f" ]]; then
  PKG_IDENTIFIER="com.matthewdenwood"
  PKG_KEYCHAIN="Developer ID: Matthew Denwood"
  if grep "official macOS binary" "sign/JAGS-$BUILD/opt/jags/versions/jags/$BUILD/share/man/man1/jags.1"; then
    echo "Signing official JAGS binary"
  else
    echo "The indicated build of JAGS was not compiled with the 'official' string - do make clean and try again" 1>&2
    exit $EX_CONFIG
  fi
fi

## Build dependency manifest and sign runnables (including scripts):

## Make a list of archs and dependencies for checking:
cd "sign/JAGS-$BUILD"
BINDEPFILE="$WDIR/sign/JAGS-$BUILD/binary_dependencies.txt"
echo "Binary dependencies:\n" >> "$BINDEPFILE"
for dd in $(find "opt" -type d -print); do
  for ff in $(ls "$dd"); do
    ftype=$(file -I "$dd/$ff")
    sign=0
    # If a binary:
    if echo "$ftype" | grep -q "application/x-mach-binary"; then
      # That isn't a symlink:
      if test ! -L "$dd/$ff"; then
        ## Output dependencies, architectures and macos min versions for checking:
        echo "$ff" >> "$BINDEPFILE"
        otool -L "$dd/$ff" >> "$BINDEPFILE"
        lipo -archs "$dd/$ff" >> "$BINDEPFILE"
        otool -l "$dd/$ff" | grep -E -A4 '(LC_VERSION_MIN_MACOSX|LC_BUILD_VERSION)' | grep -B1 sdk >> "$BINDEPFILE"
        echo "     -> Signed by $DEVELOPER_APPLICATION \n\n" >> "$BINDEPFILE"      
        sign=1
      fi
    fi
    # Or a shell script:
    if [[ "$ff" == "jags" ]] || [[ "$ff" == "jags-version" ]] || [[ "$ff" == "jags-uninstall" ]]; then
      sign=1
    fi
    # And not a folder:
    if [[ -d "$dd/$ff" ]]; then
      sign=0
    fi
    # Then sign:
    if [[ $sign -eq 1 ]]; then
      echo "Signing: $dd/$ff"
      xcrun codesign --force --timestamp --options runtime --sign "$DEVELOPER_APPLICATION" "$dd/$ff"
    fi    
  done
done

cd "$WDIR"

# Copy in the post-installation script:
mkdir -p "sign/JAGS-$BUILD/scripts"
cp "build/postinstall-jags.sh" "sign/JAGS-$BUILD/scripts/postinstall"
sed -i '' "s/__BUILD__/${BUILD}/g" "sign/JAGS-$BUILD/scripts/postinstall"
chmod +x "sign/JAGS-$BUILD/scripts/postinstall"
cp "utils/jags-version.sh" "sign/JAGS-$BUILD/scripts/jags-version"
chmod +x "sign/JAGS-$BUILD/scripts/jags-version"

## Then create pkg file:
pkgbuild --root "sign/JAGS-$BUILD/opt/" \
         --identifier "$PKG_IDENTIFIER.jags-$VBUILD" \
         --version "$VERSION" \
         --install-location "/opt/" \
         --scripts "sign/JAGS-$BUILD/scripts" \
         "sign/JAGS-$BUILD.pkg"

## Then remove the ._ files manually:
echo "Removing dotbars..."
scripts/package-remove-dotbar.sh "sign/JAGS-$BUILD.pkg" "pkg/JAGS-$BUILD.pkg"
echo "Wrote package to pkg/JAGS-$BUILD.pkg"

exit $EX_OK
