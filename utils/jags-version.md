---
title: jags-version
section: 1
header: JAGS Utilities User Manuals
---

<!---
SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
SPDX-License-Identifier: Apache-2.0
-->

# NAME
jags-version - switch the active build/version of JAGS

# SYNOPSIS
**jags-version** [*-h*] [*-l*] BUILD

# DESCRIPTION
**jags-version** is a command-line utility that can be used to switch between active versions/builds
of JAGS (https://mcmc-jags.sourceforge.io) created by the official JAGS installers for macOS.
The -l option lists the JAGS builds/versions that can be switched.
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

# OPTIONS
**-h**
: Display a help message and exit.

**-l**
: List the available builds of JAGS (any BUILD argument is ignored).

**BUILD**
: Switch to the build/version of JAGS matching this string.

# NOTES
Modification of the active JAGS build normally requires the utility to be
run as root (e.g. using sudo) - alternatively you can make yourself owner
of the relevant directory, after which sudo will not (usually) be needed:
  
  sudo chown -R $USER /opt/jags/versions/jags

# SEE ALSO
http://mcmc-jags.sourceforge.net and https://github.com/mdenwood/JAGS-build-macOS

# AUTHORS
Matthew Denwood (@mdenwood)

# LICENSE
This script is distributed 'as is', both FREELY and WITHOUT CHARGE, under the 
Apache License version 2.0, via https://github.com/mdenwood/JAGS-build-macOS
and the macOS official binaries of JAGS (https://mcmc-jags.sourceforge.io).
