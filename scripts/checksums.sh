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

exit $EX_OK
