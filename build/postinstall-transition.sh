#!/bin/zsh

# Abort on error, use of unset variable, or error within pipe:
set -euo pipefail

# Return codes:
EX_OK=0
EX_USAGE=64
EX_CONFIG=78

# Check we are running as root:
if [ $(id -u) -ne 0 ]; then
    echo "Error: the postinstall script must be run as root" >&2
    exit $EX_USAGE
fi

# Remove arm64 JAGS 4.x
rm -rf /opt/R/arm64/bin/jags
rm -rf /opt/R/arm64/bin/jags-uninstall
rm -rf /opt/R/arm64/libexec/jags-terminal
rm -rf /opt/R/arm64/include/JAGS/
rm -rf /opt/R/arm64/lib/libjags.4.dylib
rm -rf /opt/R/arm64/lib/pkgconfig/jags.pc
rm -rf /opt/R/arm64/lib/JAGS/
rm -rf /opt/R/arm64/lib/libjrmath.0.dylib
rm -rf /opt/R/arm64/lib/libjrmath.la
rm -rf /opt/R/arm64/lib/libjags.la
rm -rf /opt/R/arm64/share/man/man1/jags.1

# Remove universal/x86_64 JAGS 4.x
rm -rf /usr/local/bin/jags
rm -rf /usr/local/bin/jags-uninstall
rm -rf /usr/local/libexec/jags-terminal
rm -rf /usr/local/include/JAGS/
rm -rf /usr/local/lib/libjags.4.dylib
rm -rf /usr/local/lib/pkgconfig/jags.pc
rm -rf /usr/local/lib/JAGS/
rm -rf /usr/local/lib/libjrmath.0.dylib
rm -rf /usr/local/lib/libjrmath.la
rm -rf /usr/local/lib/libjags.la
rm -rf /usr/local/share/man/man1/jags.1

# Remove symlinks
rm -rf /usr/local/bin/jags
rm -rf /usr/local/bin/jags-uninstall
rm -rf /usr/local/bin/jags-switch
rm -rf /usr/local/bin/jags-version
rm -rf /usr/local/lib/pkgconfig/jags.pc
rm -rf /usr/local/share/man/man1/jags.1  
rm -rf /usr/local/share/man/man1/jags-uninstall.1  
rm -rf /usr/local/share/man/man1/jags-switch.1
rm -rf /usr/local/share/man/man1/jags-version.1 

# Remove JAGS 5 beta files/symlinks
setopt extended_glob glob_dots        # Enable extended globbing (provides the '^' negation operator) and glob_dots (includes hidden/dot files in the match)
rm -rf -- ^"/opt/jags/versions"(D)    # Delete all files (including hidden files) except /opt/jags/versions

# Create symlinks under /opt/jags
mkdir -p "/opt/jags/bin"
mkdir -p "/opt/jags/lib/pkgconfig"
mkdir -p "/opt/jags/share/man/man1"
ln -fs "/opt/jags/versions/jags/current/bin/jags" "/opt/jags/bin/jags"
ln -fs "/opt/jags/versions/utils/current/jags-4" "/opt/jags/bin/jags-4"
ln -fs "/opt/jags/versions/utils/current/jags-5" "/opt/jags/bin/jags-5"
ln -fs "/opt/jags/versions/utils/current/jags-uninstall" "/opt/jags/bin/jags-uninstall"
ln -fs "/opt/jags/versions/utils/current/jags-version" "/opt/jags/bin/jags-version"
ln -fs "/opt/jags/versions/jags/current/lib/pkgconfig/jags.pc" "/opt/jags/lib/pkgconfig/jags.pc"
ln -fs "/opt/jags/versions/jags/current/share/man/man1/jags.1" "/opt/jags/share/man/man1/jags.1"
ln -fs "/opt/jags/versions/utils/current/jags-uninstall.1" "/opt/jags/share/man/man1/jags-uninstall.1"
ln -fs "/opt/jags/versions/utils/current/jags-version.1" "/opt/jags/share/man/man1/jags-version.1"

# Create symlinks under /usr/local
mkdir -p "/usr/local/bin"
mkdir -p "/usr/local/lib/pkgconfig"
mkdir -p "/usr/local/share/man/man1"
ln -fs "/opt/jags/bin/jags" "/usr/local/bin/jags" 
ln -fs "/opt/jags/lib/pkgconfig/jags.pc" "/usr/local/lib/pkgconfig/jags.pc" 
ln -fs "/opt/jags/share/man/man1/jags.1" "/usr/local/share/man/man1/jags.1" 

exit $EX_OK
