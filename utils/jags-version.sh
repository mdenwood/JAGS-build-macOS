#!/bin/zsh

# SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
# SPDX-License-Identifier: Apache-2.0

# Utility shell script to switch the active JAGS version
# For help/options run jags-version --help
# This utility is (also) distributed as part of the macOS installers for JAGS (https://mcmc-jags.sourceforge.io)

# Abort on error, use of unset variable, or error within pipe:
set -euo pipefail

# Arguments
help=0
printerror=0
list=0
interactive=0
target=""

while getopts ":lh?" flag; do
  if [[ $flag == "l" ]]; then
    list=1
  elif [[ $flag == "h" ]]; then
  	help=1
  elif [[ $flag == "?" ]]; then
  	printerror=1
  fi
done
shift $((OPTIND -1))

if [[ "$#" -eq 0 ]]; then
  if [[ $list -eq 0 ]]; then
    list=1
    interactive=1
  fi
elif [[ "$#" -eq 1 ]]; then
  target="$1"
else
  printerror=1
fi

# Return codes:
EX_OK=0
EX_USAGE=64
EX_SOFTWARE=70
EX_NOPERM=77

## Check we are on macOS >= 11:
if [ "`echo $OSTYPE | grep 'darwin'`" = "" ]; then
	echo "This script requires macOS" 1>&2 
	exit $EX_USAGE
fi
minvers=11.0
currvers=`sw_vers -productVersion | tr -d ' '`
if [ "$(echo -e $minvers"\n"$currvers | sort -V | tail -1)" = "$minvers" ]; then
  echo "This script requires macOS 11 (Big Sur) or greater" 1>&2 
	exit $EX_USAGE
fi

# Usage:
if [ $printerror -eq 1 ]; then
  printf "Usage:  jags-version [build]\n"
	printf "\tFor the manual page use:  jags-version -h\n"
	exit $EX_USAGE	
fi

if [[ $help -eq 1 ]]; then
	# Horrible hack of a function to allow overstriking (bold) for less (tput doesn't work...):
	embold ()
	{
	str=`echo $1`
	out=""
	for (( i=0; i<${#str}; i++ )); do
	out="$out${str:$i:1}\b${str:$i:1}"
	done

	echo "$out"
	return 0
	}

	printf "
`embold "jags-version -- part of JAGS for macOS utilities version __VERSION__"`
by Matt Denwood

`embold SYNOPSIS`
A zsh script that facilitates changing the active JAGS build/version on
macOS. The -l option lists the JAGS builds/versions that can be switched.
Otherwise, providing a single argument causes the active JAGS installation
to be changed to the build/version provided by modifying the symlinks
provided at /opt/jags/versions/jags/default and current-XX (where XX is the
major version of JAGS). This should allow hot-switching of most JAGS builds
with the same major version (i.e. minor updates and/or versions with 
different BLAS linkage) without re-installing rjags. Note that switching
the active JAGS installation between major versions should leave rjags
functional with linkage to the previous major version: changing the major
JAGS version for rjags requires re-installation of the rjags package.
In some cases (such as switching to/from a OpenMP build of JAGS),
re-compilation of rjags will be needed after changing the active JAGS build.

`embold USAGE`
`embold jags-version` `embold -l`
`embold jags-version` `embold build`
`embold jags-version` `embold -h`

`embold OPTIONS`
The following options are available:
`embold -l`  List the available JAGS installations.
`embold -h`  Print this help message and exit.

`embold ARGUMENTS`
The following arguments are available:
`embold build`  The desired build/version of JAGS to switch to (one of the
    available options listed by running `embold jags-version` `embold -h`.

`embold NOTES`
Modification of the active JAGS build normally requires the utility to be
run as root (e.g. using sudo) - alternatively you can make yourself owner
of the relevant directory, after which sudo will not (usually) be needed:
  
  sudo chown -R \$USER /opt/jags/versions/jags

This script is distributed 'as is', both FREELY and WITHOUT CHARGE, under the 
Apache License version 2.0, via https://github.com/mdenwood/JAGS-build-macOS
and the macOS official binaries of JAGS (https://mcmc-jags.sourceforge.io).

"

	exit $EX_OK
fi


# Check for legacy/custom JAGS installations and warn:
legacy=0
if [[ -d "/usr/local/include/JAGS/" ]]; then
  legacy=1
fi
if [[ -d "/opt/R/arm64/include/JAGS/" ]]; then
  legacy=1
fi
if [[ $legacy -eq 1 ]]; then
  echo "Note: custom/legacy JAGS versions were detected;\nremove these via jags-uninstall -c if the wrong version persists"
fi

## Check for symlinks under /usr/local:
#if [[ $symlinks -eq 1 ]] && [[ -L "/usr/local/bin/jags" ]]; then
#  jags_sym=1
#else
#  jags_sym=0
#fi

# Check for an official JAGS version folder:
if [[ ! -d "/opt/jags/versions/jags" ]]; then
  echo "Error: no installation under /opt/jags/versions/jags detected!\nPlease re-install JAGS using an official macOS installer." 1>&2
  exit $EX_USAGE
fi

# Display avaialble JAGS builds:
if [[ -d "/opt/jags/versions/jags/default" ]]; then
  default=$(readlink /opt/jags/versions/jags/default)
else
  default="UNSET"
fi
if [[ $list -eq 1 ]]; then
  if [[ $interactive -eq 1 ]]; then
    echo "Select one of the following JAGS builds:"
    index=1
    versions=()
  else
    echo "The following JAGS builds are available:"
  fi
  for ff in $(ls /opt/jags/versions/jags); do
    if test ! -L "/opt/jags/versions/jags/$ff"; then
      if [[ -f "/opt/jags/versions/jags/$ff/include/JAGS/version.h" ]]; then
        
        majvers=$(cat "/opt/jags/versions/jags/$ff/include/JAGS/version.h" | grep "JAGS_MAJOR" | cut -d " " -f 3)
        invalid=0
        case $majvers in
            <0->) ;;
            *) invalid=1 ;;
        esac
        if [[ $invalid -eq 1 ]]; then
          echo "Error: Invalid JAGS version in /opt/jags/versions/jags/$ff/include/JAGS/version.h" 1>&2
          exit $EX_USAGE
        fi
        
        if [[ -d "/opt/jags/versions/jags/current-$majvers" ]]; then
          currentv=$(readlink /opt/jags/versions/jags/current-$majvers)
        else
          currentv="UNSET"
        fi
        
        printf "\t"
        if [[ $interactive -eq 1 ]]; then
          versions+=($ff)
          printf "$index:  "
          index=$((index+1))
        fi
        printf "$ff"
        if [[ "$default" == "/opt/jags/versions/jags/$ff" ]] && [[ "$currentv" == "/opt/jags/versions/jags/$ff" ]]; then
          printf " (current-$majvers & default)"
        elif [[ "$currentv" == "/opt/jags/versions/jags/$ff" ]]; then
          printf " (current-$majvers)"
        elif [[ "$default" == "/opt/jags/versions/jags/$ff" ]]; then
          printf " (default)"
        fi
        printf "\n"
      fi
    fi
  done
  
  if [[ $interactive -eq 1 ]]; then
    printf "Enter your selection:  "
    read choice
    invalid=0
    case $choice in
        <1->) ;;
        *) invalid=1 ;;
    esac
    if [[ $choice -gt $index ]]; then
      invalid=1
    fi
    if [[ $invalid -eq 1 ]]; then
      echo "Error: Invalid selection" 1>&2
      exit $EX_USAGE
    fi
    target=$versions[$choice]
  else
    exit $EX_OK
  fi
fi

# Check to see if the required JAGS is there (target can be blank):
if [[ ! -d "/opt/jags/versions/jags/$target" ]]; then
  echo "Error: no JAGS build at /opt/jags/versions/jags/$target detected!\nUse jags-version -l to display available builds." 1>&2
  exit $EX_USAGE  
fi

# Test we are either running as root or sudo (unless we are the owner of the /opt/jags/versions/jags directory):
if [ ! -O "/opt/jags/versions/jags/" ] && [ $UID -ne 0 ]; then
    echo "Error: jags-version must be run using sudo (or as root) to switch the active JAGS build" >&2
    echo "Usage: sudo $0 $@" >&2
    exit $EX_USAGE
fi

# Extract major version:
majvers=$(echo $target | cut -d "." -f 1)    

# Verify that the required directories and symlinks are present:
for dd ("/opt/jags/bin" "/opt/jags/lib/pkgconfig" "/opt/jags/lib/pkgconfig-$majvers" "/opt/jags/share/man/man1"); do
  if [[ ! -d "$dd" ]]; then
    if [ $UID -ne 0 ]; then
        echo "Error: jags-version must be run using sudo (or as root) to create the required directory structure" >&2
        echo "Usage: sudo $0 $@" >&2
        exit $EX_USAGE
    fi  
    # echo "Making directory $dd"
    mkdir -p "$dd"    
  fi    
done
for ff ("bin/jags" "share/man/man1/jags.1"); do
    if [[ ! "$(readlink -n "/opt/jags/$ff")" == "/opt/jags/versions/jags/default/$ff" ]]; then
      if [ $UID -ne 0 ]; then
          echo "Error: jags-version must be run using sudo (or as root) to create the required symlinks" >&2
          echo "Usage: sudo $0 $@" >&2
          exit $EX_USAGE
      fi            
      # echo "Making symlink for /opt/jags/$ff"
      ln -fs "/opt/jags/versions/jags/default/$ff" "/opt/jags/$ff"
    fi
done
if [[ ! "$(readlink -n "/opt/jags/lib/pkgconfig/jags.pc")" == "/opt/jags/versions/jags/default/lib/pkgconfig/jagsv.pc" ]]; then
  if [ $UID -ne 0 ]; then
      echo "Error: jags-version must be run using sudo (or as root) to create the required symlinks" >&2
      echo "Usage: sudo $0 $@" >&2
      exit $EX_USAGE
  fi            
  # echo "Making symlink for /opt/jags/lib/pkgconfig/jags.pc"
  ln -fs "/opt/jags/versions/jags/default/lib/pkgconfig/jagsv.pc" "/opt/jags/lib/pkgconfig/jags.pc"
fi
for vv ("$majvers"); do
  if [[ ! "$(readlink -n "/opt/jags/lib/pkgconfig-$vv/jags.pc")" == "/opt/jags/versions/jags/current-$vv/lib/pkgconfig/jagsv.pc" ]]; then
    if [ $UID -ne 0 ]; then
        echo "Error: jags-version must be run using sudo (or as root) to create the required symlinks" >&2
        echo "Usage: sudo $0 $@" >&2
        exit $EX_USAGE
    fi            
    # echo "Making symlink for /opt/jags/lib/pkgconfig-$vv/jags.pc"
    ln -fs "/opt/jags/versions/jags/current-$vv/lib/pkgconfig/jagsv.pc" "/opt/jags/lib/pkgconfig-$vv/jags.pc"
  fi
done
# Fix utils installation if needed and present:
for ff ("bin/jags-4" "bin/jags-5" "bin/jags-uninstall" "bin/jags-version" "share/man/man1/jags-4.1" "share/man/man1/jags-5.1" "share/man/man1/jags-uninstall.1" "share/man/man1/jags-version.1"); do
  if [[ -f "/opt/jags/versions/utils/latest/$ff" ]]; then
    if [[ ! "$(readlink -n "/opt/jags/$ff")" == "/opt/jags/versions/utils/latest/$ff" ]]; then
      if [ $UID -ne 0 ]; then
          echo "Error: jags-version must be run using sudo (or as root) to create the required symlinks" >&2
          echo "Usage: sudo $0 $@" >&2
          exit $EX_USAGE
      fi            
      # echo "Making symlink for /opt/jags/$ff"
      ln -fs "/opt/jags/versions/utils/latest/$ff" "/opt/jags/$ff"
    fi
  fi
done


# Check for presence of the modified pkg-config file:
if [[ ! -f "/opt/jags/versions/jags/$target/lib/pkgconfig/jagsv.pc" ]]; then
  if [ $UID -ne 0 ]; then
      echo "Error: jags-version must be run using sudo (or as root) to modify pkg-config files" >&2
      echo "Usage: sudo $0 $@" >&2
      exit $EX_USAGE
  fi
  
  if [[ ! -f "/opt/jags/versions/jags/$target/lib/pkgconfig/jags.pc" ]]; then
    echo "Error: /opt/jags/versions/jags/$target/lib/pkgconfig/jags.pc was not found (invalid JAGS installation)" >&2
    exit $EX_SOFTWARE
  fi
    
  # Duplicate and modify the pkg-config file:
  cp "/opt/jags/versions/jags/$target/lib/pkgconfig/jags.pc" "/opt/jags/versions/jags/$target/lib/pkgconfig/jagsv.pc"
  sed -i "" -e "s|prefix=/opt/jags/versions/jags/$target|prefix=/opt/jags/versions/jags/current-$majvers|g" "/opt/jags/versions/jags/$target/lib/pkgconfig/jagsv.pc"  
fi

# Check if we are moving between major versions of JAGS:
if [[ -f "/opt/jags/versions/jags/default/include/JAGS/version.h" ]]; then  
  oldmajvers=$(cat "/opt/jags/versions/jags/default/include/JAGS/version.h" | grep "JAGS_MAJOR" | cut -d " " -f 3)
  if [[ $oldmajvers -ne $majvers ]]; then
    echo "Note: switching between major versions of JAGS ($oldmajvers -> $majvers) does not affect the rjags package without re-compilation"
  fi  
fi

# Check the jagsv.pc file to see if it is the same as the currently linked version:
if [[ -f "/opt/jags/lib/pkgconfig-$majvers/jags.pc" ]]; then
  # echo "Checking to see if the jags.pc file is changed..."
  if ! cmp -s "/opt/jags/lib/pkgconfig-$majvers/jags.pc" "/opt/jags/versions/jags/$target/lib/pkgconfig/jagsv.pc"; then
    echo "Note: the JAGS-$majvers build indicated ($target) has a different \npkg-config file to the previous build ($default); \nyou may need to re-compile rjags"
  fi
fi

# Update active version:
ln -Fs "/opt/jags/versions/jags/$target" "/opt/jags/versions/jags/default"
ln -Fs "/opt/jags/versions/jags/$target" "/opt/jags/versions/jags/current-$majvers"

echo "JAGS build $target is now current-$majvers & default"
exit $EX_OK
