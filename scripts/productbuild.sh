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
if ! [ -f "pkg/JAGS-4.3.2-vecLib-single-$ARCH.pkg" ]; then
  echo "One or more JAGS .pkg file not found" >&2
  exit $EX_CONFIG
fi
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

echo "\n\n**** TODO:  automate updating versions within Distribution.xml based on arguments to productbuild.sh *****\n\n"

## Make installer to pkg
productbuild --distribution "build/Distribution.xml" --package-path "./pkg" --resources "./build" "pkg/JAGS-$VERSION-$ARCH.pkg"

echo "Build product saved to pkg/JAGS-$VERSION-$ARCH.pkg"

exit $EX_OK
