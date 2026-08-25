#!/bin/zsh

# SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
# SPDX-License-Identifier: Apache-2.0

# Abort on error:
set -e

# Return codes:
EX_OK=0
EX_USAGE=64
EX_CONFIG=78

if [ "$#" -ne 0 ]; then
    echo "Error: 0 arguments required (got $#)."
    exit $EX_USAGE
fi

## Eliminate homebrew etc path:
export PATH=" /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

## Check we are on macOS >= 11:
if [ "`echo $OSTYPE | grep 'darwin'`" = "" ]; then
	echo "This script requires macOS" 1>&2 
	exit $EX_CONFIG
fi
minvers=11.0
currvers=`sw_vers -productVersion | tr -d ' '`
if [ "$(echo -e $minvers"\n"$currvers | sort -V | tail -1)" = "$minvers" ]; then
  echo "This script requires macOS 11 (Big Sur) or greater" 1>&2 
	exit $EX_CONFIG
fi

## Check this is an Apple silicon mac
if [[ ! "`uname -m`" == "arm64" ]]; then
	echo "Warning: this script has only been tested on Apple silicon (arm64/aarch64)" 1>&2 
fi

## Check Xcode command line tools are installed:
if ! ( xcode-select -p >/dev/null ); then
  echo "Command line tools are not installed:  run:\n xcode-select --install" 1>&2
  exit $EX_CONFIG
fi

## Check rosetta is available (not actually needed):
#if ! ( arch -arch x86_64 whoami > /dev/null ) ; then
#  echo "Rosetta not installed - run:\n /usr/sbin/softwareupdate --install-rosetta --agree-to-license" 1>&2 
#  exit $EX_CONFIG
#fi

## Check SDK is available:
if ! [ -d /Library/Developer/CommandLineTools/SDKs/MacOSX11.sdk ]; then
  echo "SDK not found - find and download e.g. McOSX11.3.sdk then run:\n cd /Library/Developer/CommandLineTools/SDKs/; sudo ln -s MacOSX11.3.sdk MacOSX11.sdk" 1>&2
  exit $EX_CONFIG
fi
SDKROOT=`readlink -f "/Library/Developer/CommandLineTools/SDKs/MacOSX11.sdk"`
if [ "$SDKROOT" = "" ]; then
  echo "SDK not found by readlink" 1>&2
  exit $EX_CONFIG
fi

## Check Simon's gfortran is installed:
if ! [ -f "/opt/gfortran/bin/aarch64-apple-darwin20.0-gfortran" ]; then
  echo "CRAN build of gfortran not available:  install from https://mac.r-project.org/tools/" 1>&2
  exit $EX_CONFIG
fi

## Ensure that gfortran exists and is set up with the SDK correctly:
if [ ! -f "/opt/gfortran/bin/gfortran" ]; then
  echo "Error:  gfortran not found at /opt/gfortran" 1>&2 
  exit $EX_USAGE
fi
GSDK=`readlink -f /opt/gfortran/SDK`
if [ "$GSDK" != "$SDKROOT" ]; then
  echo "Error: gfortran SDK is not configured for binary compatibility with official builds of R.\nYou should run the following command:\n\tsudo /opt/gfortran/bin/gfortran-update-sdk $SDKROOT" 1>&2 
  echo "After re-running the compile script you can reset the gfortran SDK by running:\n\tsudo /opt/gfortran/bin/gfortran-update-sdk" 1>&2 
  exit $EX_USAGE
fi  

exit $EX_OK
