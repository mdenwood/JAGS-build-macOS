---
title: jags-uninstall
section: 1
header: JAGS Utilities User Manuals
---

<!---
SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
SPDX-License-Identifier: Apache-2.0
-->

# NAME
jags-uninstall - remove installations of JAGS

# SYNOPSIS
**jags-uninstall** [*-h*] [*-c*] [*-o*] [*-s*] [*-d*]

# DESCRIPTION
**jags-uninstall** is a command-line tool that can be used to remove installations
of JAGS (https://mcmc-jags.sourceforge.io) created by the official JAGS installers for macOS.
The default option removes **all** detected installations including custom and
legacy (version <= 4.x) builds in /usr/local/ and/or /opt/R/arm64 as well
as official (version >= 5.x) builds under /opt/jags. To fine-tune this 
behaviour see the available options below.

# OPTIONS
**-h**
: Display a help message and exit.

**-c**
: Over-ride the default and remove only custom/legacy JAGS installations under /usr/local and/or /opt/R/arm64 (unless the -o flag is also set).

**-o**
: Over-ride the default and remove only official JAGS installations under /opt/jags and (unless the -c flag is also set) - this option also implies -s.

**-s**
: Over-ride the default and remove only symlinks under /usr/local that point to /opt/jags/current (unless the -o or -c flag is also set).

**-d**
: Perform a dry-run i.e. list the files/directories that would be removed but don't actually do anything.

# SEE ALSO
http://mcmc-jags.sourceforge.net and https://github.com/mdenwood/JAGS-build-macOS

# AUTHORS
Matthew Denwood (@mdenwood)

# LICENSE
This script is distributed 'as is', both FREELY and WITHOUT CHARGE, under the 
Apache License version 2.0, via https://github.com/mdenwood/JAGS-build-macOS
and the macOS official binaries of JAGS (https://mcmc-jags.sourceforge.io).
