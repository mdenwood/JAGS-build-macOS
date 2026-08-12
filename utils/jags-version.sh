#!/bin/zsh

# Utility shell script to switch the active JAGS version
# For help/options run jags-version --help

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
A zsh script that facilitates switching the active JAGS installation on
macOS. The -l option lists the official JAGS builds that can be switched
(i.e. version 5.x and above, as well as the version 4.3.2 binary included
with the JAGS 5.0.0-beta installer). Otherwise, the build option causes
the active JAGS to be switched to that build/version by modifying symlinks
provided at /opt/jags/current and /opt/jags/current-XX (where XX is the
major version of JAGS). This should allow hot-switching of JAGS releases
with the same major version (i.e. minor updates and/or versions with 
different BLAS linkage) without re-installing rjags. Note that switching
the active JAGS installation between major versions should leave rjags
functional with linkage to the previous major version: changing the major
JAGS version for rjags requires re-installation of the rjags package.

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
This script is distributed 'as is', both FREELY and WITHOUT CHARGE, under the 
GNU general public license version 2.0, as part of the macOS official binaries
of JAGS (https://mcmc-jags.sourceforge.io).

"

	exit $EX_OK
fi


# Temporary:
echo $target
mkdir "/opt/jags/versions/current-$target"

exit 0


# Check for legacy/custom JAGS installations and warn:
legacy=0
if [[ -d "/usr/local/lib/JAGS/" ]]; then
  legacy=1
fi
if [[ -d "/opt/R/arm64/lib/JAGS/" ]]; then
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
if [[ ! -d "/opt/jags/" ]]; then
  echo "Error: no installation under /opt/jags detected!\nPlease re-install JAGS using the official macOS installer." 1>&2
  exit $EX_USAGE
fi

# Display avaialble JAGS builds:
current=$(readlink /opt/jags/bin/jags)
if [[ $list -eq 1 ]]; then
  if [[ $interactive -eq 1 ]]; then
    echo "Select one of the following JAGS builds:"
    index=1
    versions=()
  else
    echo "The following JAGS builds are available:"
  fi
  for ff in $(ls /opt/jags); do
    if test ! -L "/opt/jags/$ff"; then
      if [[ -f "/opt/jags/$ff/include/JAGS/version.h" ]]; then
        
        majvers=$(cat "/opt/jags/$ff/include/JAGS/version.h" | grep "JAGS_MAJOR" | cut -d " " -f 3)
        invalid=0
        case $majvers in
            <0->) ;;
            *) invalid=1 ;;
        esac
        if [[ $invalid -eq 1 ]]; then
          echo "Error: Invalid JAGS version in /opt/jags/$ff/include/JAGS/version.h" 1>&2
          exit $EX_USAGE
        fi
        
        currentv=$(readlink /opt/jags/$majvers.x-current)
        printf "\t"
        if [[ $interactive -eq 1 ]]; then
          versions+=($ff)
          printf "$index:  "
          index=$((index+1))
        fi
        printf "$ff"
        if [[ "$(readlink -- /opt/jags/bin/jags)" == "/opt/jags/$ff/bin/jags" ]] && [[ "/opt/jags/$ff" == "$currentv" ]]; then
          printf " ($majvers.x-current & default)"
        elif [[ "/opt/jags/$ff" == "$currentv" ]]; then
          printf " ($majvers.x-current)"
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
if [[ ! -d "/opt/jags/$target" ]]; then
  echo "Error: no JAGS build at /opt/jags/$target detected!\nUse jags-version -l to display available builds." 1>&2
  exit $EX_USAGE  
fi

# TODO:
# If option -c is given then use sudo chown -vh to change ownership on the symlinks below to the current user so they can be modified without sudo in future
# Test permissions BUT this is for the file the symlink points to, i.e. useless:
if test -L -a -w "/opt/jags/bin/jags"; then;
  echo "writeable"
else
  echo "not writeable"
fi

# Need to harvest the owner from this?
ls -lF "/opt/jags/bin/jags"
ls -lF "/opt/jags/5.x-current"


# Escalate permissions:
sudo -v -p "Enter password to proceed with sudo: "

# Switch:
majvers=$(echo $target | cut -d "." -f 1)
sudo ln -Fs "/opt/jags/$target" "/opt/jags/$majvers.x-current"
sudo ln -fs "/opt/jags/$target/bin/jags" "/opt/jags/bin/jags"
sudo ln -Fs "/opt/jags/$target/include" "/opt/jags/include"
sudo ln -Fs "/opt/jags/$target/lib" "/opt/jags/lib"
sudo ln -Fs "/opt/jags/$target/libexec" "/opt/jags/libexec"
sudo ln -fs "/opt/jags/$target/share/man/man1/jags.1" "/opt/jags/share/man/man1/jags.1"

echo "$target is now $majvers.x-current & default"
exit $EX_OK
