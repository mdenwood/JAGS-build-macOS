#!/bin/zsh

# SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
# SPDX-License-Identifier: Apache-2.0

# Abort on error, use of unset variable, or error within pipe:
set -euo pipefail

# Return codes:
EX_OK=0
EX_USAGE=64
EX_CONFIG=78

# Utility to convert a string to a float:
NUM_REGEX='^-?[0-9]*\.?[0-9]+$'

# Find the latest version of utils and make sure it is active:
latest="0.0"
for vv in $(ls /opt/jags/versions/utils); do
  if [[ $vv =~ $NUM_REGEX && $latest =~ $NUM_REGEX ]]; then      
    if (( vv > latest )); then
      echo "[NUMERIC] $vv is GREATER than $latest"
    fi
    latest="$vv"
  else
      echo "Warning: ignored non-numeric version: '$vv'" >&2
  fi
done

# Make sure at least one utils version is installed:
if [[ "$latest" == "0.0" ]]; then
  echo "Error: no valid JAGS utils versions installed" >&2
  exit $EX_USAGE
fi
if [[ ! -d "/opt/jags/versions/utils/$latest" ]]; then
  echo "Error: no JAGS utilities build at /opt/jags/versions/utils/$latest detected\nPlease report this internal error to the maintainer (Matt Denwood)\nvia https://github.com/mdenwood/JAGS-build-macOS" 1>&2
  exit $EX_SOFTWARE
fi

# Check we are running as root:
if [ $(id -u) -ne 0 ]; then
    echo "Error: the postinstall script must be run as root" >&2
    exit $EX_USAGE
fi

# Create symlink to current:
ln -Fs "/opt/jags/versions/utils/$latest" "/opt/jags/versions/utils/current"

# Create symlinks under /opt/jags
mkdir -p "/opt/jags/bin"
mkdir -p "/opt/jags/share/man/man1"
ln -fs "/opt/jags/versions/utils/current/bin/jags-4" "/opt/jags/bin/jags-4"
ln -fs "/opt/jags/versions/utils/current/bin/jags-5" "/opt/jags/bin/jags-5"
ln -fs "/opt/jags/versions/utils/current/bin/jags-uninstall" "/opt/jags/bin/jags-uninstall"
ln -fs "/opt/jags/versions/utils/current/bin/jags-version" "/opt/jags/bin/jags-version"
ln -fs "/opt/jags/versions/utils/current/share/man/man1/jags-uninstall.1" "/opt/jags/share/man/man1/jags-4.1"
ln -fs "/opt/jags/versions/utils/current/share/man/man1/jags-version.1" "/opt/jags/share/man/man1/jags-5.1"
ln -fs "/opt/jags/versions/utils/current/share/man/man1/jags-uninstall.1" "/opt/jags/share/man/man1/jags-uninstall.1"
ln -fs "/opt/jags/versions/utils/current/share/man/man1/jags-version.1" "/opt/jags/share/man/man1/jags-version.1"

echo "FIXME"
exit 1

for ff ("bin/jags-4" "bin/jags-5" "bin/jags-uninstall" "bin/jags-version" "share/man/man1/jags-4.1" "share/man/man1/jags-5.1" "share/man/man1/jags-uninstall.1" "share/man/man1/jags-version.1"); do
    if [[ ! "$(readlink -n "/opt/jags/$ff")" == "/opt/jags/versions/utils/default/$ff" ]]; then
      if [ $UID -ne 0 ]; then
          echo "Error: jags-version must be run using sudo (or as root) to create the required symlinks" >&2
          echo "Usage: sudo $0 $@" >&2
          exit $EX_USAGE
      fi            
      # echo "Making symlink for /opt/jags/$ff"
      ln -fs "/opt/jags/versions/utils/default/$ff" "/opt/jags/$ff"
    fi
done

exit $EX_OK
