#!/bin/zsh

# SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
# SPDX-License-Identifier: Apache-2.0

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
if [ "$#" -ne 0 ]; then
    echo "Error: 0 arguments required (got $#)."
    echo "Usage: $0"
    exit $EX_USAGE
fi

## Print checksums for all files under release:
rm -f release/checksums.txt
for ff in $(ls release); do
  cs=$(shasum -a 256 "release/$ff" | awk '{print $1}')
  echo "\n- $ff:\n\t$cs" >> release/checksums.txt
done

exit 1

if [[ "$VERSION" == "5.0.0" ]]; then
  if [[ ! $(shasum -a 256 "sources/JAGS-$VERSION.tar.gz" | awk '{print $1}') ==  
        "64fcd4883b8a8ee907722f49366cc9f277477a0647ada61356f17568f84ffff8" ]]; then
    echo "Invalid SHA256 checksum for JAGS version $VERSION" >&2
    exit $EX_USAGE
  fi
elif [[ "$VERSION" == "4.3.2" ]]; then
  if [[ ! $(shasum -a 256 "sources/JAGS-$VERSION.tar.gz" | awk '{print $1}') ==  
        "871f556af403a7c2ce6a0f02f15cf85a572763e093d26658ebac55c4ab472fc8" ]]; then
    echo "Invalid SHA256 checksum for JAGS version $VERSION" >&2
    exit $EX_USAGE
  fi
else
  for ff in $(ls "sources"); do
    echo "$ff: $(shasum -a 256 "sources/$ff" | awk '{print $1}')"
  done
  echo "Unable to validate download: no SHA256 checksum available for JAGS version $VERSION" >&2
  exit $EX_SOFTWARE
fi

exit $EX_OK
