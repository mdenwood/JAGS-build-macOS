# JAGS-build-macOS

This repository contains a Makefile (and associated shell scripts) for building the official macOS installers of JAGS, along with the canonical macOS JAGS utility scripts.  Note that the artefacts (JAGS installers) themselves are (currently) NOT hosted here; see e.g. https://sourceforge.net/projects/mcmc-jags/files/JAGS/5.x/macOS/ for these.

Most users will simply want to download one of the pre-built installers from sourceforge (see link above). This repository is primarily for the benefit of the maintainer of the macOS binaries of JAGS (i.e. me) to streamline the build/release process for JAGS, but full transparency of the build process is also a good thing. The scripts may also be useful to other users on macOS that wish to build their own JAGS binaries while maintaining full compatibility with the official CRAN builds of R and the rjags/runjags/etc packages.

Note that the scripts are NOT intended to be portable between platforms:  a recent build of macOS on an arm64/aarch64 machine is assumed.


## Makefile

TODO


## Directory structure

The "utils" folder contains the canonical versions of the macOS JAGS utilities (jags-version and jags-uninstall) as well as their man pages.

The "build" folder contains files required to build the official macOS installers for JAGS

The "scripts" folder contains zsh scripts that perform the steps necessary from downloading a JAGS source tarball through compilation and (if desired) to producing a .pkg installer.  This includes downloading, compiling and (locally) installing the required tools pkg-config, cppunit and Netlib's BLAS/LAPACK.  These are intended to be run by GNU make (see above for a description of the make targets).

Additional folders will be created by make as needed.


## Pre-requisites

Expand the MacOSX11.3 SDK into /Library/Developer/CommandLineTools/SDKs/ and then run:

cd /Library/Developer/CommandLineTools/SDKs
sudo ln -s MacOSX11.3.sdk MacOSX11.sdk
SDKROOT=`readlink -f "/Library/Developer/CommandLineTools/SDKs/MacOSX11.sdk"`

Install homebrew, pkg-config, gfortran and rosetta:
brew install pkg-config
/usr/sbin/softwareupdate --install-rosetta --agree-to-license

BUT make sure homebrew gcc and fortran are not in the PATH!!!

export PATH="/opt/homebrew/Cellar/pkgconf/2.5.1/bin:/opt/cppunit/current/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/opt/pkg/env/active/bin:/opt/pmk/env/global/bin:/Library/TeX/texbin:/Applications/iTerm.app/Contents/Resources/utilities:/opt/gfortran/bin:/usr/local/bin/"


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
        │   ├── 5.0.0-vecLib-gcd-aarch64
        │   ├── ...
        │   ├── 5.x-current                     : symlink (directory)
        │   └── current                         : symlink (directory)
        └── utils/
            ├── 1.0.0
            ├── ...
            └── current                         : symlink (directory)

To fit within this structure, JAGS is configured with a prefix of /opt/jags/versions/jags/5.x-current (or 4.x-current, for JAGS 4.x), but the installed files are moved to an installation path under /opt/jags/versions/jags/VERSION-BLAS-THREAD-ARCH so that multiple installations can co-exist and be switched on/off using the jags-version utility.  Note that the tools required to build jags (pkg-config, cppunit and Netlib's LAPACK) are only installed within the self-contained repo directory (under lib).


## Installers produced

JAGS (and utils) builds are produced as:

- Individual-build JAGS/utils .tgz files under the tgz directory - these are not signed, and do not require an Apple Developer account to build

- Individual-build JAGS/utils .pkg files under the pkg directory - these are signed, and do require an Apple Developer account

- A transition.pkg file under the pkg directory - this can be run to remove previous versions of JAGS 4.x from /usr/local and /opt/R/arm64/ and JAGS 5 beta from /opt/jags, and install symlinks to /opt/jags under /usr/local for backwards compatibility without needing to update the PATH environmental variable

- A combined build JAGS-$VERSION.pkg file under the pkg directory - this is also signed, and contains the default individual pkg files (currently refBLAS-single-universal, vecLib-single-universal, vecLib-gcd-universal, utils and transition)

The individual pkg installers each run a post-install script to ensure that the newly installed JAGS build is selected as the default.  These are also run when installing these via the combined pkg installer.  The post-install script for utils always activates the latest available version; to activate an earlier version you will first have to remove newer versions of utils from /opt/jags/versions/utils manually.
