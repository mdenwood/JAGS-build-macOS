#!/bin/zsh

# Utility shell script to remove all detected JAGS installations
# For help/options run jags-uninstall --help
# Matt Denwood, 2026-04-23

# Arguments
custom=0
official=0
symlinks=0
dryrun=0
help=0
printerror=0

while getopts ":cosdh?" flag; do
  if [[ $flag == "c" ]]; then
  	custom=1
  elif [[ $flag == "o" ]]; then
  	official=1
    symlinks=1
  elif [[ $flag == "s" ]]; then
  	symlinks=1
  elif [[ $flag == "d" ]]; then
  	dryrun=1
  elif [[ $flag == "h" ]]; then
  	help=1
  elif [[ $flag == "?" ]]; then
  	printerror=1
  fi
done

# Default is -cos
if [[ $custom -eq 0 ]] && [[ $official -eq 0 ]] && [[ $symlinks -eq 0 ]]; then
  custom=1
  official=1
  symlinks=1
fi

# No arguments are allowed:
shift $(( $OPTIND-1 ))
if [[ "$#" -ne 0 ]]; then
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
  printf "Usage:  jags-uninstall [-c] [-o] [-s] [-d]\n" 1>&2 
	printf "\tFor the manual page use:  jags-uninstall -h\n" 1>&2 
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
`embold "jags-uninstall -- part of JAGS for macOS utilities version 1.0"`
by Matt Denwood

`embold SYNOPSIS`
A zsh script that facilitates removal of JAGS installations on macOS. The
default option removes `embold all` detected installations including custom and
legacy (version <= 4.x) builds in /usr/local/ and/or /opt/R/arm64 as well
as official (version >= 5.x) builds under /opt/jags. To fine-tune this 
behaviour see the available options below.

`embold USAGE`
`embold jags-uninstall` [`embold -c`] [`embold -o`] [`embold -s`] [`embold -d`]
`embold jags-uninstall` `embold -h`

`embold OPTIONS`
The following options are available:
`embold -c`  Over-ride the default and remove only custom/legacy JAGS
    installations under /usr/local and/or /opt/R/arm64 (unless the -o flag 
    is also set).
`embold -o`  Over-ride the default and remove only official JAGS
    installations under /opt/jags and (unless the -c flag is also set) - this
    option also implies -s.
`embold -s`  Over-ride the default and remove only symlinks under /usr/local
    that point to /opt/jags/current (unless the -o or -c flag is also set).
`embold -d`  Perform a dry-run i.e. list the files/directories that would be
    removed but don't actually do anything.
`embold -h`  Print this help message and exit.

`embold NOTES`
This script is distributed 'as is', both FREELY and WITHOUT CHARGE, under the 
GNU general public license version 2.0, as part of the macOS official binaries
of JAGS (https://mcmc-jags.sourceforge.io).

"

	exit $EX_OK
fi

# Check for official JAGS >=5 installation:
if [[ $official -eq 1 ]] && [[ -d "/opt/jags" ]]; then
  jags_opt=1
else
  jags_opt=0
fi

# Check for legacy/custom JAGS installations:
if [[ $custom -eq 1 ]] && [[ -d "/usr/local/lib/JAGS/" ]]; then
  jags_usr=1
else
  jags_usr=0  
fi
if [[ $custom -eq 1 ]] && [[ -d "/opt/R/arm64/lib/JAGS/" ]]; then
  jags_optR=1
else
  jags_optR=0
fi

# Check for symlinks under /usr/local:
if [[ $symlinks -eq 1 ]] && [[ -L "/usr/local/bin/jags" ]]; then
  jags_sym=1
else
  jags_sym=0
fi

if [[ $jags_opt -eq 0 ]] && [[ $jags_optR -eq 0 ]] && [[ $jags_usr -eq 0 ]] && [[ $jags_sym -eq 0 ]]; then
  echo "No JAGS installations found" 1>&2
  exit $EX_USAGE
fi

if [[ $dryrun -eq 0 ]]; then
  echo "The following JAGS installations will be removed:"
else
  echo "The following JAGS installations would be removed:"
fi

if [[ $jags_usr -eq 1 ]]; then
  echo "\t- Legacy or custom JAGS installation under /usr/local/"
fi
if [[ $jags_optR -eq 1 ]]; then
  echo "\t- Legacy or custom JAGS installation under /opt/R/arm64/"
fi
if [[ $jags_opt -eq 1 ]]; then
  for ff in `ls /opt/jags`; do
    if test ! -L "/opt/jags/$ff"; then
      if [[ ! "$ff" == "bin" ]] && [[ ! "$ff" == "share" ]]; then
        vers=$(echo $ff | cut -d "-" -f 1)
        echo "\t- JAGS version $vers installation at /opt/jags/$ff/"
      fi
    fi
  done
  echo "\t- Symlinks and subdirectories at /opt/jags/"
fi
if [[ $jags_sym -eq 1 ]]; then
  echo "\t- Symlinks under /usr/local/"
fi

# Exit early if only a dry run:
if [[ $dryrun -eq 1 ]]; then
  exit $EX_OK
fi

# Escalate permissions:
sudo -v -p "Enter password to proceed with sudo: "

if [[ $jags_sym -eq 1 ]]; then
  sudo rm -rf "/usr/local/bin/jags"
  sudo rm -rf "/usr/local/bin/jags-uninstall"
  sudo rm -rf "/usr/local/bin/jags-switch"
  sudo rm -rf "/usr/local/lib/pkgconfig/jags.pc"
  sudo rm -rf "/usr/local/share/man/man1/jags.1"  
  sudo rm -rf "/usr/local/share/man/man1/jags-uninstall.1"  
  sudo rm -rf "/usr/local/share/man/man1/jags-switch.1"  
fi

if [[ $jags_opt -eq 1 ]]; then
  sudo rm -rf "/opt/jags/"
fi

if [[ $jags_optR -eq 1 ]]; then
  sudo rm -rf /opt/R/arm64/bin/jags
  sudo rm -rf /opt/R/arm64/bin/jags-uninstall
  sudo rm -rf /opt/R/arm64/libexec/jags-terminal
  sudo rm -rf /opt/R/arm64/include/JAGS/
  sudo rm -rf /opt/R/arm64/lib/libjags.4.dylib
  sudo rm -rf /opt/R/arm64/lib/pkgconfig/jags.pc
  sudo rm -rf /opt/R/arm64/lib/JAGS/
  sudo rm -rf /opt/R/arm64/lib/libjrmath.0.dylib
  sudo rm -rf /opt/R/arm64/lib/libjrmath.la
  sudo rm -rf /opt/R/arm64/lib/libjags.la
  sudo rm -rf /opt/R/arm64/share/man/man1/jags.1
fi

if [[ $jags_usr -eq 1 ]]; then
  sudo rm -rf /usr/local/bin/jags
  sudo rm -rf /usr/local/bin/jags-uninstall
  sudo rm -rf /usr/local/libexec/jags-terminal
  sudo rm -rf /usr/local/include/JAGS/
  sudo rm -rf /usr/local/lib/libjags.4.dylib
  sudo rm -rf /usr/local/lib/pkgconfig/jags.pc
  sudo rm -rf /usr/local/lib/JAGS/
  sudo rm -rf /usr/local/lib/libjrmath.0.dylib
  sudo rm -rf /usr/local/lib/libjrmath.la
  sudo rm -rf /usr/local/lib/libjags.la
  sudo rm -rf /usr/local/share/man/man1/jags.1
fi

echo "JAGS uninstallation complete"
exit $EX_OK
