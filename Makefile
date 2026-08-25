# SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
# SPDX-License-Identifier: Apache-2.0

## Versions of JAGS, CPPUNIT and LAPACK to use
JAGSVERSION := 5.0.0
UTILSVERSION := 1.0.0
CPPUNITVERS := 1.15.1
LAPACKVERS := 3.12.1
PKGCONFVERS := 3.0.5
PKGCONFIGVERS := 0.29.2

## Extract JAGS major version from full version
VERSMAJ = $(word 1,$(subst ., ,$(JAGSVERSION)))

## Save all intermediate targets even when not mentioned explicitly:
.SECONDARY:
	
## Complete build
.PHONY: all
all: tools tmp/JAGS-$(JAGSVERSION)-vecLib-single-aarch64/.stamp
# all: tools tmp/JAGS-$(JAGSVERSION)-vecLib-single-x86_64/.stamp tmp/JAGS-$(JAGSVERSION)-vecLib-gcd-aarch64/.stamp tmp/JAGS-$(JAGSVERSION)-vecLib-gcd-x86_64/.stamp tmp/JAGS-$(JAGSVERSION)-vecLib-single-aarch64/.stamp tmp/JAGS-$(JAGSVERSION)-refBLAS-single-aarch64/.stamp tmp/JAGS-$(JAGSVERSION)-refBLAS-single-x86_64/.stamp
# all: build/JAGS-$(JAGSVERSION)-vecLib-gcd-universal.pkg
# all: tmp/JAGS-$(JAGSVERSION)-vecLib-single-universal/.stamp
# all: sign/utils-$(UTILSVERSION).pkg utils/man/jags-4.1 utils/man/jags-5.1 sign/transition-$(UTILSVERSION).pkg sign/JAGS-$(JAGSVERSION)-vecLib-gcd-aarch64.pkg


## Create folders

.PHONY: mkdirs
mkdirs: | sources tmp tools tgz sign pkg release

sources:					# For downloading source files
	mkdir sources
tmp:							# Temp directory for compilation
	mkdir tmp
tools:						# For built tools
	mkdir tools
tgz:							# For (potentially lipo'd) unsigned tarballs
	mkdir tgz
sign:						  # Temp directory for signing and verifying dependencies
	mkdir sign
pkg:							# For installers (code is signed but not stapled)
	mkdir pkg
release:					# For all signed/stapled installers including productbuild output
	mkdir release


## Download source files

.PHONY: download
download: sources/JAGS-$(JAGSVERSION).tar.gz sources/LAPACK-$(LAPACKVERS).tar.gz sources/cppunit-$(CPPUNITVERS).tar.gz sources/pkgconf-$(PKGCONFVERS).tar.gz #sources/pkg-config-$(PKGCONFIGVERS).tar.gz 

sources/JAGS-$(JAGSVERSION).tar.gz: | sources
	curl -OL --output-dir sources https://sourceforge.net/projects/mcmc-jags/files/JAGS/$(VERSMAJ).x/Source/JAGS-$(JAGSVERSION).tar.gz

sources/JAGS-4.3.2.tar.gz: | sources
	curl -OL --output-dir sources https://sourceforge.net/projects/mcmc-jags/files/JAGS/4.x/Source/JAGS-4.3.2.tar.gz
	
sources/LAPACK-$(LAPACKVERS).tar.gz: | sources
	curl -L --output sources/LAPACK-$(LAPACKVERS).tar.gz https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v$(LAPACKVERS).tar.gz
	
sources/cppunit-$(CPPUNITVERS).tar.gz: | sources
	curl -OL --output-dir sources http://dev-www.libreoffice.org/src/cppunit-$(CPPUNITVERS).tar.gz

sources/pkgconf-$(PKGCONFVERS).tar.gz: | sources
	curl -L --output sources/pkgconf-$(PKGCONFVERS).tar.gz https://github.com/pkgconf/pkgconf/archive/refs/tags/pkgconf-$(PKGCONFVERS).tar.gz

sources/pkg-config-$(PKGCONFIGVERS).tar.gz: | sources
	curl -OL --output-dir sources https://pkg-config.freedesktop.org/releases/pkg-config-$(PKGCONFIGVERS).tar.gz
	

## Build tools

.PHONY: all-tools
all-tools: tools/.stamp
	
tools/.stamp: tools/cppunit/.stamp tools/lapack/.stamp tools/pkgconf-lite/.stamp #tools/pkg-config/.stamp #tools/omp/.stamp
	touch tools/.stamp

tools/cppunit/.stamp: scripts/cppunit.sh sources/cppunit-$(CPPUNITVERS).tar.gz | tools tmp
	./scripts/cppunit.sh $(CPPUNITVERS)

tools/lapack/.stamp: scripts/lapack.sh sources/LAPACK-$(LAPACKVERS).tar.gz | tools tmp
	./scripts/lapack.sh $(LAPACKVERS)

tools/pkgconf-lite/.stamp: scripts/pkgconf.sh sources/pkgconf-$(PKGCONFVERS).tar.gz | tools tmp
	./scripts/pkgconf.sh $(PKGCONFVERS)

tools/pkg-config/.stamp: scripts/pkgconfig.sh sources/pkg-config-$(PKGCONFIGVERS).tar.gz | tools tmp
	./scripts/pkgconfig.sh $(PKGCONFIGVERS)

# TODO: omp download
tools/omp/.stamp: scripts/omp.sh sources/v$(LAPACKVERS).tar.gz | tools tmp
	./scripts/omp.sh $(LAPACKVERS)


## Ensure the customised JAGS manual is updated:
utils/man/jags.1: utils/jags.md
	pandoc utils/jags.md -s -t man -o utils/man/jags.1


## Compile JAGS

# Build dependent on all tools, even when we don't need e.g. LAPACK/OMP, for ease:
tmp/JAGS-$(JAGSVERSION)-%-aarch64/.stamp: scripts/jags-compile.sh sources/JAGS-$(JAGSVERSION).tar.gz tools/.stamp utils/man/jags.1 | tmp
	./scripts/jags-compile.sh $(JAGSVERSION) "$*-aarch64"
tmp/JAGS-$(JAGSVERSION)-%-x86_64/.stamp: scripts/jags-compile.sh sources/JAGS-$(JAGSVERSION).tar.gz tools/.stamp utils/man/jags.1 | tmp
	./scripts/jags-compile.sh $(JAGSVERSION) "$*-x86_64"

tmp/JAGS-4.3.2-vecLib-single-aarch64/.stamp: scripts/jags-compile.sh sources/JAGS-4.3.2.tar.gz tools/.stamp utils/man/jags.1 | tmp
	./scripts/jags-compile.sh 4.3.2 "vecLib-single-aarch64"
tmp/JAGS-4.3.2-vecLib-single-x86_64/.stamp: scripts/jags-compile.sh sources/JAGS-4.3.2.tar.gz tools/.stamp utils/man/jags.1 | tmp
	./scripts/jags-compile.sh 4.3.2 "vecLib-single-x86_64"


## Lipo JAGS

tmp/JAGS-$(JAGSVERSION)-%-universal/.stamp: scripts/jags-lipo.sh tmp/JAGS-$(JAGSVERSION)-%-aarch64/.stamp tmp/JAGS-$(JAGSVERSION)-%-x86_64/.stamp
	./scripts/jags-lipo.sh $(JAGSVERSION) "$*"
tmp/JAGS-4.3.2-%-universal/.stamp: scripts/jags-lipo.sh tmp/JAGS-4.3.2-%-aarch64/.stamp tmp/JAGS-4.3.2-%-x86_64/.stamp
	./scripts/jags-lipo.sh 4.3.2 "$*"


## Make tgz files

tgz/JAGS-%.tgz: tmp/JAGS-%/.stamp | tgz
	tar -zcf tgz/JAGS-$*.tgz -C tmp/JAGS-$* opt


## Sign code, make dependency manifest and create pkg

pkg/JAGS-%.pkg: scripts/package-jags.sh tgz/JAGS-%.tgz build/postinstall-jags.sh utils/jags-version.sh | sign pkg
	./scripts/package-jags.sh $*


## FIXME BELOW

## Create transition pkg

pkg/transition-$(UTILSVERSION).pkg: scripts/package-transition.sh build/postinstall-transition-$(UTILSVERSION).sh pkg/JAGS-4.3.2-vecLib-single-universal.pkg | sign pkg
	./scripts/package-transition.sh $(UTILSVERSION)

## TODO: transition should allow new JAGS 4 to work with CRAN rjags


## Create utils pkg
utils/man/jags-%.1: utils/jags-%.md utils/utils-vers.sh
	pandoc utils/jags-$*.md -s -t man -M footer="Version $(UTILSVERSION)" -o utils/man/jags-$*.1

pkg/utils-$(UTILSVERSION).pkg: scripts/package-utils.sh utils/jags-0.sh utils/jags-version.sh utils/jags-uninstall.sh utils/man/jags-0.1 utils/man/jags-version.1 utils/man/jags-uninstall.1 build/postinstall-utils.sh | sign pkg
	./scripts/package-utils.sh $(UTILSVERSION)


## Create pkgconf pkg

## Use productbuild to make (and staple) main release:
release/JAGS-$(JAGSVERSION).pkg: scripts/productbuild.sh pkg/JAGS-$(JAGSVERSION)-refBLAS-single-universal.pkg pkg/JAGS-$(JAGSVERSION)-vecLib-single-universal.pkg pkg/JAGS-$(JAGSVERSION)-vecLib-gcd-universal.pkg | release
	./scripts/productbuild.sh $(JAGSVERSION)


## Staple additional releases:
release/JAGS-%.pkg: scripts/staple.sh pkg/JAGS-%.pkg | release
	./scripts/staple.sh "JAGS-$*"

release/utils-$(UTILSVERSION).pkg: scripts/staple.sh pkg/utils-$(UTILSVERSION).pkg | release
	./scripts/staple.sh "utils-$(UTILSVERSION)"

# ETC

.PHONY: releases
releases: release/JAGS-$(JAGSVERSION).pkg # etc
