## Versions of JAGS, CPPUNIT and LAPACK to use
JAGSVERSION := 5.0.0
UTILSVERSION := 1.0
CPPUNITVERS := 1.15.1
LAPACKVERS := 3.12.1
PKGCONVERS := 0.29.2

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
mkdirs: | sources tmp tools tgz sign pkg build

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
pkg:							# For signed installers
	mkdir pkg
build:						# For productbuild output
	mkdir build


## Download source files

.PHONY: download
download: sources/JAGS-$(JAGSVERSION).tar.gz sources/v$(LAPACKVERS).tar.gz sources/cppunit-$(CPPUNITVERS).tar.gz sources/pkg-config-$(PKGCONVERS).tar.gz

sources/JAGS-$(JAGSVERSION).tar.gz: | sources
	curl -OL --output sources https://sourceforge.net/projects/mcmc-jags/files/JAGS/$(VERSMAJ).x/Source/JAGS-$(JAGSVERSION).tar.gz
	
sources/v$(LAPACKVERS).tar.gz: | sources
	curl -OL --output sources https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v3.12.1.tar.gz
	
sources/cppunit-$(CPPUNITVERS).tar.gz: | sources
	curl -OL --output sources http://dev-www.libreoffice.org/src/cppunit-$(CPPUNITVERS).tar.gz

sources/pkg-config-$(PKGCONVERS).tar.gz: | sources
	curl -OL --output sources https://pkg-config.freedesktop.org/releases/pkg-config-$(PKGCONVERS).tar.gz
	

## Build tools

.PHONY: all-tools
all-tools: tools/pkg-config/.stamp tools/cppunit/.stamp tools/lapack/.stamp #tools/omp/.stamp

tools/pkg-config/.stamp: scripts/pkgconfig.sh sources/pkg-config-$(PKGCONVERS).tar.gz | tools
	./scripts/pkgconfig.sh $(PKGCONVERS)

tools/cppunit/.stamp: scripts/cppunit.sh sources/cppunit-$(CPPUNITVERS).tar.gz | tools
	./scripts/cppunit.sh $(CPPUNITVERS)

tools/lapack/.stamp: scripts/lapack.sh sources/v$(LAPACKVERS).tar.gz | tools
	./scripts/lapack.sh $(LAPACKVERS)

# TODO: omp download
tools/omp/.stamp: scripts/omp.sh sources/v$(LAPACKVERS).tar.gz | tools
	./scripts/omp.sh $(LAPACKVERS)


## Compile JAGS

# Note: we could do this, but then the lipo rule won't always have a shorter stem:
# tmp/JAGS-$(JAGSVERSION)-%/.stamp: scripts/jags-compile.sh sources/JAGS-$(JAGSVERSION).tar.gz tools/pkg-config/.stamp tools/cppunit/.stamp
# 	./scripts/jags-compile.sh $(JAGSVERSION) "$*"
# tmp/JAGS-$(JAGSVERSION)-refBLAS-%/.stamp: scripts/jags-compile.sh sources/JAGS-$(JAGSVERSION).tar.gz tools/pkg-config/.stamp tools/cppunit/.stamp tools/lapack/.stamp
# 	./scripts/jags-compile.sh $(JAGSVERSION) "refBLAS-$*"

# So actually just always build dependent on all tools:
tmp/JAGS-$(JAGSVERSION)-%/.stamp: scripts/jags-compile.sh sources/JAGS-$(JAGSVERSION).tar.gz all-tools


## Lipo JAGS

tmp/JAGS-$(JAGSVERSION)-%-universal/.stamp: scripts/jags-lipo.sh tmp/JAGS-$(JAGSVERSION)-%-aarch64/.stamp tmp/JAGS-$(JAGSVERSION)-%-x86_64/.stamp
	./scripts/jags-lipo.sh $(JAGSVERSION) "$*"


## Make tgz files

tgz/JAGS-%.tgz: tmp/JAGS-%/.stamp | tgz
	tar -zcf tgz/JAGS-$*.tgz -C tmp/JAGS-$* opt


## Sign, make dependency manifest and create pkg

sign/JAGS-%.pkg: scripts/package-jags.sh tgz/JAGS-%.tgz | sign pkg
	./scripts/package-jags.sh $*


## Create transition pkg

sign/transition-$(UTILSVERSION).pkg: scripts/package-transition.sh build/postinstall-transition-$(UTILSVERSION).sh | sign pkg
	./scripts/package-transition.sh $(UTILSVERSION)


## Create utils pkg
utils/man/jags-%.1: utils/jags-%.md utils/utils-vers.sh
	pandoc utils/jags-$*.md -s -t man -M footer="Version $(UTILSVERSION)" -o utils/man/jags-$*.1

sign/utils-$(UTILSVERSION).pkg:
	./scripts/package-utils.sh $(UTILSVERSION)

## Create JAGS installers

