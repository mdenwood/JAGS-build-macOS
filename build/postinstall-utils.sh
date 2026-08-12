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

# Create symlinks under /opt/jags
mkdir -p "/opt/jags/bin"
mkdir -p "/opt/jags/lib/pkgconfig"
mkdir -p "/opt/jags/share/man/man1"
ln -fs "/opt/jags/versions/utils/current/bin/jags-4" "/opt/jags/bin/jags-4"
ln -fs "/opt/jags/versions/utils/current/bin/jags-5" "/opt/jags/bin/jags-5"
ln -fs "/opt/jags/versions/utils/current/bin/jags-uninstall" "/opt/jags/bin/jags-uninstall"
ln -fs "/opt/jags/versions/utils/current/bin/jags-version" "/opt/jags/bin/jags-version"
ln -fs "/opt/jags/versions/utils/current/share/man/man1/jags-uninstall.1" "/opt/jags/share/man/man1/jags-4.1"
ln -fs "/opt/jags/versions/utils/current/share/man/man1/jags-version.1" "/opt/jags/share/man/man1/jags-5.1"
ln -fs "/opt/jags/versions/utils/current/share/man/man1/jags-uninstall.1" "/opt/jags/share/man/man1/jags-uninstall.1"
ln -fs "/opt/jags/versions/utils/current/share/man/man1/jags-version.1" "/opt/jags/share/man/man1/jags-version.1"

exit $EX_OK

