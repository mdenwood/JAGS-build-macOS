#!/bin/zsh

# SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
# SPDX-License-Identifier: Apache-2.0

# Utility shell script to launch a specific version of JAGS
# This utility is (also) distributed as part of the macOS installers for JAGS (https://mcmc-jags.sourceforge.io)

# Return codes:
local EX_OK=0
local EX_USAGE=64
local EX_CONFIG=78

## Hard-code:
local MAJ="__MAJ__"

# Default build:
local BUILD="current-$MAJ"

# Possible script argument:
local SCRIPT=""

for arg in "$@"; do
  # Extract possible build:
  if [[ "$arg" == -b=* ]] || [[ "$arg" == --build=* ]]; then
    if [[ "$BUILD" == "current-$MAJ" ]]; then
      BUILD="${arg#*=}"
    else
      echo "Error: multiple -b and --build options detected" >&2
      exit $EX_USAGE
    fi
    continue
  elif [[ "$arg" == -d* ]] || [[ "$arg" == --debugger* ]]; then
    echo "Debugger options ($arg) are not supported by jags-$MAJ - use jags directly" >&2
    exit $EX_USAGE    
  elif [[ "$arg" == -* || "$arg" == --* ]]; then
    echo "Unsupported option: $arg" >&2
    exit $EX_USAGE
  else
    if [[ "$SCRIPT" == "" ]]; then
      SCRIPT="$arg"
    else
      echo "Error: multiple arguments detected - only --build option and a\nsingle (scriptfile) argument are supported" >&2
      exit $EX_USAGE
    fi
    continue
  fi
done

## Verify that the specified build exists:
if [[ ! -d "/opt/jags/versions/jags/$BUILD" ]]; then
  echo "Error: no JAGS build at /opt/jags/versions/jags/$BUILD detected!\nUse jags-version -l to display available builds." 1>&2
  exit $EX_USAGE  
fi
majvers=$(cat "/opt/jags/versions/jags/$BUILD/include/JAGS/version.h" | grep "JAGS_MAJOR" | cut -d " " -f 3)
if [[ ! "$majvers" == "$MAJ" ]]; then
  echo "Error: the JAGS build specified has a major version number of $majvers not $MAJ" 1>&2
  exit $EX_USAGE  
fi 

## Set prefix:
local PREFIX="/opt/jags/versions/jags/$BUILD"

## Set environmental variables:
if test -z "${LD_LIBRARY_PATH}"; then
   export LD_LIBRARY_PATH="${PREFIX}/lib"
else
   export LD_LIBRARY_PATH="${PREFIX}/lib:${LD_LIBRARY_PATH}"
fi
export LTDL_LIBRARY_PATH="${JAGS_LIBS}:${PREFIX}/lib/JAGS/modules-${MAJ}"

## Startup with or without script:
if [[ "$SCRIPT" == "" ]]; then
  exec "${PREFIX}/bin/jags"
else
  exec "${PREFIX}/bin/jags" "${SCRIPT}"
fi
