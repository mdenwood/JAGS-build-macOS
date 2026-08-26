# JAGS-build-macOS

This repository contains a Makefile (and associated shell scripts) for building the official macOS installers of JAGS, along with the canonical macOS JAGS utility scripts.  Note that the artefacts (JAGS installers) themselves are (currently) NOT hosted here; see e.g. https://sourceforge.net/projects/mcmc-jags/files/JAGS/5.x/macOS/ for these.

Most users will simply want to download one of the pre-built installers from sourceforge (see link above). This repository is primarily for the benefit of the maintainer of the macOS binaries of JAGS (i.e. me) to streamline the build/release process for JAGS, but full transparency of the build process is also a good thing. The scripts may also be useful to other users on macOS that wish to build their own JAGS binaries while maintaining full compatibility with the official CRAN builds of R and the rjags/runjags/etc packages.

Note that the scripts are NOT intended to be portable between platforms:  a recent build of macOS on an arm64/aarch64 machine is assumed.


## Available make targets

TODO


## Directory structure

The "utils" folder contains the canonical versions of the macOS JAGS utilities (jags-version and jags-uninstall) as well as their man pages.

The "build" folder contains files required to build the official macOS installers for JAGS

The "scripts" folder contains zsh scripts that perform the steps necessary from downloading a JAGS source tarball through compilation and (if desired) to producing a .pkg installer.  This includes downloading, compiling and (locally) installing the required tools pkg-config, cppunit and Netlib's BLAS/LAPACK.  These are intended to be run by GNU make (see above for a description of the make targets).

Additional folders will be created by make as needed.


## Pre-requisites

The following system-level dependencies must be installed before attempting to run make:

- Apple's Xcode command-line tools:  xcode-select --install

- The universal GNU Fortran 14.2 compiler available from https://cran.r-project.org/bin/macosx/tools/

- Rosetta:  /usr/sbin/softwareupdate --install-rosetta --agree-to-license

- The MacOSX11.3 SDK (software development kit) - run scripts/check_deps.sh for instructions

Make will automatically download and compile the dependencies cppunit, LAPACK, and pkgconf-lite before attempting to compile JAGS.  Note that any PATH environmental variable you have set is ignored to ensure that the build process only picks up the standard Apple-provided build tools and specific version of gfortran given above.


## Installation directory

These installation scripts are designed for JAGS to use a versioned installation directory structure with symlinks under bin, lib and share as follows:

/opt/
└── jags/
    ├── bin/
    │   ├── jags                                : symlink to inside /opt/jags/versions/jags/current
    │   ├── jags-4                              : symlink to inside /opt/jags/versions/jags/4.x-current
    │   ├── jags-5                              : symlink to inside /opt/jags/versions/jags/5.x-current
    │   ├── jags-uninstall                      : symlink to inside /opt/jags/versions/utils/current
    │   └── jags-version                        : symlink to inside /opt/jags/versions/utils/current
    ├── lib
    │   ├── pkgconfig
    │   │   └── jags.pc                         : Modified pkg-config file for generic linkage to JAGS
    │   ├── pkgconfig-4
    │   │   └── jags.pc                         : Modified pkg-config file for generic linkage to JAGS 4.x
    │   └── pkgconfig-5
    │       └── jags.pc                         : Modified pkg-config file for generic linkage to JAGS 5.x
    ├── share
    │   └── man
    │       └── man1
    │           ├── jags-uninstall.1            : symlink to inside /opt/jags/versions/utils/current
    │           ├── jags-version.1              : symlink to inside /opt/jags/versions/utils/current
    │           └── jags.1                      : symlink to inside /opt/jags/versions/jags/current
    │
    └── versions/
        ├── jags/
        │   ├── 4.3.2-vecLib-single-universal
        │   ├── 5.0.0-vecLib-gcd-universal
        │   ├── ...
        │   ├── current-4                       : symlink (directory)
        │   ├── current-5                       : symlink (directory)
        │   └── default                         : symlink (directory)
        ├── pkgconf-lite/
        │   ├── 3.0.5
        │   ├── ...
        │   └── current                         : symlink (directory)
        └── utils/
            ├── 1.0.0
            ├── ...
            └── current                         : symlink (directory)

To fit within this structure, JAGS is configured with a prefix of /opt/jags/versions/jags/current-5 (or current-4, for JAGS 4.x), but the installed files are moved to an installation path under /opt/jags/versions/jags/VERSION-BLAS-THREAD-ARCH so that multiple installations can co-exist and be switched on/off using the jags-version utility.  Note that the tools required only to build jags (cppunit and Netlib's LAPACK) are only installed within the self-contained repo directory (under lib).


## Installers produced

JAGS builds are produced as:

- Individual-build .tgz files under the tgz directory - these are not signed, and do not require an Apple Developer account to build

- Individual-build .pkg files under the pkg directory - these are signed, and do require an Apple Developer account to build

- A utils.pkg file under the pkg directory - this contains the jags-version etc utilities as well as pkgconf-lite (requires an Apple Developer account to build)

- A transition.pkg file under the pkg directory - this can be run to remove previous versions of JAGS 4.x from /usr/local and /opt/R/arm64/ and JAGS 5 beta from /opt/jags, install JAGS 4.3.2 within the new directory structure shown above, and install symlinks to /opt/jags under /usr/local for backwards compatibility with the CRAN build of rjags 4-x (requires an Apple Developer account to build)

- A combined build JAGS-$VERSION.pkg file under the pkg directory - this is also signed, and contains the default individual pkg files (currently refBLAS-single-universal, vecLib-single-universal, vecLib-gcd-universal, utils and transition)

The individual pkg installers each run a post-install script to ensure that the newly installed JAGS build is selected as the default.  These are also run when installing these via the combined pkg installer.  The post-install script for utils always activates the latest available version; to activate an earlier version you will first have to remove newer versions of utils from /opt/jags/versions/utils and/or /opt/jags/versions/pkgconf-lite manually (although this is not recommended).
