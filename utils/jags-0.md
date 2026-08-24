---
title: jags-[JAGSMAJVERS]
section: 1
header: JAGS Utilities User Manuals
---

<!---
SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
SPDX-License-Identifier: Apache-2.0
-->

# NAME
jags-[JAGSMAJVERS] - launch JAGS [JAGSMAJVERS].x

# SYNOPSIS
**jags-[JAGSMAJVERS]** [-b=*BUILD*] [-build=*BUILD*] [SCRIPTFILE]

# DESCRIPTION
**jags-[JAGSMAJVERS]** is a command-line utility that can be used to launch a specific version/build
of JAGS version [JAGSMAJVERS].x (https://mcmc-jags.sourceforge.io) created by the official JAGS [JAGSMAJVERS].x
installer for macOS released in August 2026 (or later), without having to run jags-version
first. To see the available JAGS builds, use **jags-version -l**

# OPTIONS
**-b=BUILD, --build=BUILD**
: An optional target build/version (otherwise the current-[JAGSMAJVERS] version will be used)

**SCRIPTFILE**
: Run JAGS in batch mode using the provided script (otherwise JAGS is launched in interactive mode)

No other options are supported - to use debuggers, call jags directly.

# SEE ALSO
http://mcmc-jags.sourceforge.net and https://github.com/mdenwood/JAGS-build-macOS

# AUTHORS
Matthew Denwood (@mdenwood)

# LICENSE
This script is distributed 'as is', both FREELY and WITHOUT CHARGE, under the 
Apache License version 2.0, via https://github.com/mdenwood/JAGS-build-macOS
and the macOS official binaries of JAGS (https://mcmc-jags.sourceforge.io).
