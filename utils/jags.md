---
title: jags
section: 1
header: JAGS User Manual
---

<!---
SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
SPDX-License-Identifier: Apache-2.0
-->

# NAME
jags - Just Another Gibbs Sampler (JAGS)

# SYNOPSIS
**jags** [*-d=DEBUGGER*] [*--debugger=DEBUGGER*] [*--debugger-args=DEBUGARGS*] [*SCRIPTFILE*]

# DESCRIPTION
**JAGS** is Just Another Gibbs Sampler.  It is a program for analysis of Bayesian hierarchical models using
Markov Chain Monte Carlo (MCMC) simulation not wholly unlike BUGS.  JAGS was written with three aims in mind:

  - To have a cross-platform engine for the BUGS language
  - To be extensible, allowing users to write their own functions, distributions and samplers
  - To be a platform for experimentation with ideas in Bayesian modelling

This is an official macOS binary of JAGS version VERSIONSTRING compiled with the following build options:

  - BLAS = BLASSTRING
  - Multi-threading = THREADSTRING
  - Architecture = ARCHSTRING

To use other JAGS builds installed on your machine, try the JAGS utilities jags-5 and jags-version.

# OPTIONS
**-d=DEBUGGER, --debugger=DEBUGGER**
: Run JAGS through the debugger provided

**--debugger-args=DEBUGARGS**
: Pass these arguments to the debugger

**SCRIPTFILE**
: Run JAGS in batch mode using the provided script (otherwise JAGS is launched in interactive mode)

# SEE ALSO
http://mcmc-jags.sourceforge.net

# AUTHORS
Martyn Plummer <martyn_plummer@sourceforge.net> 

Official macOS binaries for JAGS are provided by Matthew Denwood (@mdenwood; see https://github.com/mdenwood/JAGS-build-macOS)
