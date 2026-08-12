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

## TODO: separate making a .pkg into components and signing standalone into pkg


## Use productbuild to make a multi-pkg installer

exit 1

# Generate distribution file automatically:
productbuild --synthesize \
             --package-path ./components \
             ./Distribution.xml

productbuild --distribution ./Distribution.xml \
             --package-path ./components \
             --sign "Developer ID Installer: Your Company Name (TEAMID)" \
             ./FinalSuiteInstaller.pkg
