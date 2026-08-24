---
title: jags-5
section: 1
header: JAGS Utilities User Manuals
---

<!---
SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
SPDX-License-Identifier: Apache-2.0
-->

# NAME
jags-5 - launch JAGS 5.x

# SYNOPSIS
**jags-5** [-b=*BUILD*] [*JAGS options/arguments*]

# DESCRIPTION
**jags-5** is a command-line utility that can be used to launch a specific version/build
of JAGS version 5.x (https://mcmc-jags.sourceforge.io) created by the official JAGS 5.x
installer for macOS released in August 2026 (or later), without having to run jags-version
first.

# OPTIONS
**-b=BUILD**
: An optional target build/version (otherwise the current-5 version will be used)

All other options and arguments will be passed directly to JAGS.

# SEE ALSO
http://mcmc-jags.sourceforge.net and https://github.com/mdenwood/JAGS-build-macOS

# AUTHORS
Matthew Denwood (@mdenwood)

# LICENSE
This script is distributed 'as is', both FREELY and WITHOUT CHARGE, under the 
Apache License version 2.0, via https://github.com/mdenwood/JAGS-build-macOS
and the macOS official binaries of JAGS (https://mcmc-jags.sourceforge.io).
