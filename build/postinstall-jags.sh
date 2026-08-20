#!/bin/zsh

# SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
# SPDX-License-Identifier: Apache-2.0

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

# Run jags-version:
./jags-version __BUILD__

exit $EX_OK

