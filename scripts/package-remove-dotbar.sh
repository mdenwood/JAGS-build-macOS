#!/bin/zsh

# SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
# SPDX-License-Identifier: Apache-2.0

# Utility script to remove ._ and .DS_Store from .pkg files

# Abort on error, use of unset variable, or error within pipe:
set -euo pipefail

# Return codes:
EX_OK=0
EX_USAGE=64
EX_SOFTWARE=70
EX_CONFIG=78

## Check arguments
if [ "$#" -ne 2 ]; then
    echo "Error: 2 arguments required (got $#)."
    echo "Usage: $0 <PKG> <NEWPKG>"
    exit $EX_USAGE
fi
FILE="$1"
NEWFILE="$2"

if ! [ -f "$FILE" ]; then
  echo "Input PKG not found:  $FILE" >&2
  exit $EX_CONFIG
fi
if [ -f "$NEWFILE" ]; then
  rm $NEWFILE
fi

## Set tmp:
CWD=`pwd`
BASEWD="/tmp/package_remove_dotbar"
rm -rf "$BASEWD"
mkdir -p "$BASEWD/payload_extracted"

## Show current dotbar files:
#lsbom $(pkgutil --bom "$FILE") | grep "\._"

## Expand package:
pkgutil --expand "$FILE" "$BASEWD/expanded_pkg"

## Extract the inner binary payload:
cd "$BASEWD/payload_extracted"
cat "$BASEWD/expanded_pkg/Payload" | cpio -idmu 2> /dev/null

## Purge annoying files:
find . -name "._*" -delete
find . -name ".DS_Store" -delete

## Compress the clean assets back into the original package metadata folder:
find . | cpio -o --format odc 2> /dev/null | gzip -9 > "$BASEWD/Payload"

## Re-generate the Bill of Materials file:
mkbom . "$BASEWD/expanded_pkg/Bom"

## Re-package:
cd "$CWD"
pkgutil --flatten "$BASEWD/expanded_pkg" "$NEWFILE"

## Clean up:
rm -rf $BASEWD

## Ensure we don't have any ._ files:
DOTBARS=$(lsbom $(pkgutil --bom "$NEWFILE") 2>/dev/null | grep "\._" || true)
if [[ -n "$DOTBARS" ]]; then
  echo "Error: one or more ._ files remains:" >&2
  echo "$DOTBARS" >&2
fi

## Show new current files:
#echo "New manifest:"
#lsbom $(pkgutil --bom "$NEWFILE")

exit $EX_OK
