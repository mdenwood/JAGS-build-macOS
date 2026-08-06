# JAGS-build-macOS

This repository contains a Makefile (and associated shell scripts) for building the official macOS installers of JAGS, along with the canonical macOS JAGS utility scripts.  Note that the artefacts (JAGS installers) themselves are (currently) NOT hosted here; see e.g. https://sourceforge.net/projects/mcmc-jags/files/JAGS/5.x/macOS/ for these.

Most users will simply want to download one of the pre-built installers from sourceforge (see link above). This repository is primarily for the benefit of the maintainer of the macOS binaries of JAGS (i.e. me) to streamline the build/release process for JAGS, but full transparency of the build process is also a good thing. The scripts may also be useful to other users on macOS that wish to build their own JAGS binaries while maintaining full compatibility with the official CRAN builds of R and the rjags/runjags/etc packages.

Note that the scripts are NOT intended to be portable between platforms:  a recent build of macOS on an arm64/aarch64 machine is assumed.


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

