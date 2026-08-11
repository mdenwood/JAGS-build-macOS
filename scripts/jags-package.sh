#!/bin/zsh

# Set only if not already set:
: ${XCRUN_SIGN="Developer ID Application: Matthew Denwood"}
: ${PDBUILD_SIGN="Developer ID Installer: Matthew Denwood"}
: ${KEYCHAIN_PROFILE="Developer ID: Matthew Denwood"}

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
    echo "Usage: $0 <VERSION-BLAS-THREAD-ARCH>"
    exit $EX_USAGE
fi

BUILD="$1"
WDIR=`pwd`

## Untar into the sign directory:
rm -rf "sign/JAGS-$BUILD"
mkdir -p "sign/JAGS-$BUILD"
tar -xf "tgz/JAGS-$BUILD.tgz" -C "sign/JAGS-$BUILD"

## Extract developer identity:
set +e  # Temporarily disable stop-on-error
DEVELOPER_IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | grep -m 1 -oE '"[^"]+"' | tr -d '"')
set -e
if [ -z "$DEVELOPER_IDENTITY" ]; then
  echo "Unable to find a Developer ID Application signing certificate in your Keychain" 1>&2
  exit $EX_CONFIG
fi

## Ensure the text string is "official" if needed:
if [[ $(echo "$DEVELOPER_IDENTITY" | shasum -a 256 | awk '{print $1}') == "c4f28510cd982a3766355e2dffb4053834786200b2c89045d752155ed517c77f" ]]; then
  if grep "official" "sign/JAGS-$BUILD/opt/jags/versions/jags/$BUILD/lib/pkgconfig/jags.pc"; then
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
        echo "     -> Signed by $DEVELOPER_IDENTITY \n\n" >> "$BINDEPFILE"      
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
      xcrun codesign --force --timestamp --options runtime --sign "$DEVELOPER_IDENTITY" "$dd/$ff"
    fi    
  done
done

cd "$WDIR"

## Then create pkg file:
pkgbuild --root "sign/JAGS-$BUILD/opt/" \
         --identifier "com.matthewdenwood.jags" \
         --version "$BUILD" \
         --install-location "/opt/" \
         "pkg/JAGS-$BUILD.pkg"

exit $EX_OK
