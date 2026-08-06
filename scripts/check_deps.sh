#!/bin/zsh

# Return codes:
EX_OK=0
EX_USAGE=64
EX_CONFIG=78

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

## Check Xcode command line tools are installed:
if ! ( xcode-select -p >/dev/null ); then
  echo "Command line tools are not installed:  run:\n xcode-select --install" 1>&2
  exit $EX_CONFIG
fi

## Check rosetta is available:
if ! ( arch -arch x86_64 whoami > /dev/null ) ; then
  echo "Rosetta not installed - run:\n /usr/sbin/softwareupdate --install-rosetta --agree-to-license" 1>&2 
  exit $EX_CONFIG
fi

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

## Check pkg-config is available:
if [ `which pkg-config` = "" ]; then
  echo "pkg-config not available:  install via e.g. homebrew and ensure it is on the path" 1>&2
  exit $EX_CONFIG
fi

## Check Simon's gfortran is installed:
if ! [ -f "/opt/gfortran/bin/aarch64-apple-darwin20.0-gfortran" ]; then
  echo "CRAN build of gfortran not available:  install from https://mac.r-project.org/tools/" 1>&2
  exit $EX_CONFIG
fi

exit $EX_OK
