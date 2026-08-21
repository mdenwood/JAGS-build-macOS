#!/bin/zsh

# SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
# SPDX-License-Identifier: Apache-2.0

# Utility shell script to launch a specific version of JAGS
# This utility is (also) distributed as part of the macOS installers for JAGS (https://mcmc-jags.sourceforge.io)

# Abort on error, use of unset variable, or error within pipe:
set -euo pipefail

# Return codes:
EX_OK=0
EX_USAGE=64
EX_CONFIG=78

## Hard-code:
MAJ="__MAJ__"

# Default build:
BUILD="current-$MAJ"

# Filtered arguments to pass directly to JAGS:
local -a JAGSARGS

# Loop through all passed arguments
for arg in "$@"; do
  # Extract possible build:
  if [[ "$arg" == -b=* ]]; then
    BUILD="${arg#*-b=}"
    continue
  fi
  JAGSARGS+=("$arg")
done

## Verify the specified build exists:
if [[ ! -d "/opt/jags/versions/jags/$BUILD" ]]; then
  echo "Error: no JAGS build at /opt/jags/versions/jags/$BUILD detected!\nUse jags-version -l to display available builds." 1>&2
  exit $EX_USAGE  
fi
majvers=$(cat "/opt/jags/versions/jags/$BUILD/include/JAGS/version.h" | grep "JAGS_MAJOR" | cut -d " " -f 3)
if [[ ! "$majvers" == "$MAJ" ]]; then
  echo "Error: the JAGS build specified has a major version number of $majvers not $MAJ" 1>&2
  exit $EX_USAGE  
fi  

# Launch the specified build with arguments passed through:
/opt/jags/versions/jags/$BUILD/bin/jags "${JAGSARGS[@]}"
