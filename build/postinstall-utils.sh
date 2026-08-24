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

# Utility to compare two version strings in x.y.z format (where z or y.x can be missing):
is_later_version() {
  local -a v1 v2
  v1=(${(s:.:)1})
  v2=(${(s:.:)2})
  
  local max=$(( #v1 > #v2 ? #v1 : #v2 ))
  local ll=1    # Default is 1 = false (will be used if identical)
  local unset=0   # Default is 0 = true
  local i
  for (( i=1; i <= max; i++ )); do
    local n1=${v1[i]:-0}
    local n2=${v2[i]:-0}
    
    if [[ $n2 =~ $NUM_REGEX ]]; then
      if [[ $unset -eq 0 ]]; then
        if (( n1 < n2 )); then
          ll=0          # Make 0 = true if arg2 is later than arg1
          unset=1
        elif (( n1 > n2 )); then
          ll=1          # Make 1 = false if arg2 is later than arg1
          unset=1
        fi
      fi
    else
      return 1    # Always 1 = false if any digit is not a number
    fi
  done
  
  return ll
}
# e.g.:
#if is_later_version 1 2; then echo "1: second is later"; fi
#if is_later_version 1.0.0 1.0.2; then echo "2: second is later"; fi
#if is_later_version 1.0.0 1.0.0; then echo "3: second is later"; fi
#if is_later_version 1.0.0 1.1.x; then echo "4: second is later"; fi
#if is_later_version 1.2.0 1.1.x; then echo "5: second is later"; fi

# Find the latest version of utils and make sure it is active:
latest="0"
for vv in $(ls /opt/jags/versions/utils); do
  if is_later_version $latest $vv; then
    latest="$vv"
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

# Find the latest version of pkgconf-lite and make sure it is active:
pkglatest="0"
for vv in $(ls /opt/jags/versions/pkgconf-lite); do
  if is_later_version $pkglatest $vv; then
    pkglatest="$vv"
  fi
done

# Make sure at least one pkgconf-lite version is installed:
if [[ "$pkglatest" == "0" ]]; then
  echo "Error: no valid JAGS pkgconf-lite versions installed" >&2
  exit $EX_USAGE
fi
if [[ ! -d "/opt/jags/versions/pkgconf-lite/$pkglatest" ]]; then
  echo "Error: no JAGS pkgconf-lite build at /opt/jags/versions/pkgconf-lite/$pkglatest detected\nPlease report this internal error to the maintainer (Matt Denwood)\nvia https://github.com/mdenwood/JAGS-build-macOS" 1>&2
  exit $EX_SOFTWARE
fi

# Check we are running as root:
if [ $(id -u) -ne 0 ]; then
    echo "Error: the postinstall script must be run as root" >&2
    exit $EX_USAGE
fi

# Create symlink to latest:
ln -Fs "/opt/jags/versions/utils/$latest" "/opt/jags/versions/utils/current"
ln -Fs "/opt/jags/versions/pkgconf-lite/$pkglatest" "/opt/jags/versions/pkgconf-lite/current"

# Create symlinks under /opt/jags
mkdir -p "/opt/jags/bin"
mkdir -p "/opt/jags/share/man/man1"
ln -fs "/opt/jags/versions/utils/current/bin/jags-4" "/opt/jags/bin/jags-4"
ln -fs "/opt/jags/versions/utils/current/bin/jags-5" "/opt/jags/bin/jags-5"
ln -fs "/opt/jags/versions/utils/current/bin/jags-uninstall" "/opt/jags/bin/jags-uninstall"
ln -fs "/opt/jags/versions/utils/current/bin/jags-version" "/opt/jags/bin/jags-version"
ln -fs "/opt/jags/versions/utils/current/share/man/man1/jags.1" "/opt/jags/share/man/man1/jags.1"
ln -fs "/opt/jags/versions/utils/current/share/man/man1/jags-4.1" "/opt/jags/share/man/man1/jags-4.1"
ln -fs "/opt/jags/versions/utils/current/share/man/man1/jags-5.1" "/opt/jags/share/man/man1/jags-5.1"
ln -fs "/opt/jags/versions/utils/current/share/man/man1/jags-uninstall.1" "/opt/jags/share/man/man1/jags-uninstall.1"
ln -fs "/opt/jags/versions/utils/current/share/man/man1/jags-version.1" "/opt/jags/share/man/man1/jags-version.1"

exit $EX_OK
