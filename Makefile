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
# all: tools tmp/JAGS-$(JAGSVERSION)-vecLib-single-x86_64/.stamp tmp/JAGS-$(JAGSVERSION)-vecLib-gcd-aarch64/.stamp tmp/JAGS-$(JAGSVERSION)-vecLib-gcd-x86_64/.stamp tmp/JAGS-$(JAGSVERSION)-vecLib-single-aarch64/.stamp tmp/JAGS-$(JAGSVERSION)-refBLAS-single-aarch64/.stamp tmp/JAGS-$(JAGSVERSION)-refBLAS-single-x86_64/.stamp
# all: build/JAGS-$(JAGSVERSION)-vecLib-gcd-universal.pkg
# all: tmp/JAGS-$(JAGSVERSION)-vecLib-single-universal/.stamp
all: sign/utils-$(UTILSVERSION).pkg utils/man/jags-4.1 utils/man/jags-5.1 sign/transition-$(UTILSVERSION).pkg sign/JAGS-$(JAGSVERSION)-vecLib-gcd-aarch64.pkg


## Create folders

.PHONY: mkdirs
mkdirs: | sources tmp lib tgz sign pkg

sources:					# For downloading source files
	mkdir sources
tmp:							# Temp directory for compilation
	mkdir tmp
lib:							# For built tools (TODO: change name to tools)
	mkdir lib
tgz:							# For (potentially lipo'd) unsigned tarballs
	mkdir tgz
sign:						  # Temp directory for signing and verifying dependencies
	mkdir sign
pkg:							# For finished installers
	mkdir pkg


## Download source files

.PHONY: download
download: mkdirs download-jags download-lapack download-cppunit download-pkgconfig

.PHONY: download-jags
download-jags: sources sources/JAGS-$(JAGSVERSION).tar.gz

.PHONY: download-lapack
download-lapack: sources sources/v$(LAPACKVERS).tar.gz

.PHONY: download-cppunit
download-cppunit: sources sources/cppunit-$(CPPUNITVERS).tar.gz

.PHONY: download-pkgconfig
download-pkgconfig: sources sources/pkg-config-$(PKGCONVERS).tar.gz

sources/JAGS-$(JAGSVERSION).tar.gz: | sources
	curl -OL --output-dir sources https://sourceforge.net/projects/mcmc-jags/files/JAGS/$(VERSMAJ).x/Source/JAGS-$(JAGSVERSION).tar.gz
	
sources/v$(LAPACKVERS).tar.gz: | sources
	curl -OL --output-dir sources https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v3.12.1.tar.gz
	
sources/cppunit-$(CPPUNITVERS).tar.gz: | sources
	curl -OL --output-dir sources http://dev-www.libreoffice.org/src/cppunit-$(CPPUNITVERS).tar.gz

sources/pkg-config-$(PKGCONVERS).tar.gz: | sources
	curl -OL --output-dir sources https://pkg-config.freedesktop.org/releases/pkg-config-$(PKGCONVERS).tar.gz
	

## Build tools

# TODO: move lib to tools and then replace .PHONY tools with tools/.stamp

.PHONY: tools
tools: lib/pkg-config/.stamp lib/cppunit/.stamp lib/lapack/.stamp

lib/pkg-config/.stamp: sources/pkg-config-$(PKGCONVERS).tar.gz | lib
	./scripts/pkgconfig.sh $(PKGCONVERS)

lib/cppunit/.stamp: sources/cppunit-$(CPPUNITVERS).tar.gz | lib
	./scripts/cppunit.sh $(CPPUNITVERS)

lib/lapack/.stamp: sources/v$(LAPACKVERS).tar.gz | lib
	./scripts/lapack.sh $(LAPACKVERS)


## Compile JAGS:  TODO: use % and $* like for tgz (jags-compile will need to take two argumets only and split the BLAS-THREAD-ARCH
												# although then I can't have LAPACK as a conditional dep ... but I can have a refBLAS (and/or openmp) specific rule that will match the shortest stem

tmp/JAGS-$(JAGSVERSION)-vecLib-gcd-aarch64/.stamp: scripts/jags-compile.sh sources/JAGS-$(JAGSVERSION).tar.gz sources/pkg-config-$(PKGCONVERS).tar.gz sources/cppunit-$(CPPUNITVERS).tar.gz
	./scripts/jags-compile.sh $(JAGSVERSION) vecLib gcd aarch64

tmp/JAGS-$(JAGSVERSION)-vecLib-gcd-x86_64/.stamp: scripts/jags-compile.sh sources/JAGS-$(JAGSVERSION).tar.gz sources/pkg-config-$(PKGCONVERS).tar.gz sources/cppunit-$(CPPUNITVERS).tar.gz
	./scripts/jags-compile.sh $(JAGSVERSION) vecLib gcd x86_64

tmp/JAGS-$(JAGSVERSION)-vecLib-single-aarch64/.stamp: scripts/jags-compile.sh sources/JAGS-$(JAGSVERSION).tar.gz sources/pkg-config-$(PKGCONVERS).tar.gz sources/cppunit-$(CPPUNITVERS).tar.gz
	./scripts/jags-compile.sh $(JAGSVERSION) vecLib single aarch64

tmp/JAGS-$(JAGSVERSION)-vecLib-single-x86_64/.stamp: scripts/jags-compile.sh sources/JAGS-$(JAGSVERSION).tar.gz sources/pkg-config-$(PKGCONVERS).tar.gz sources/cppunit-$(CPPUNITVERS).tar.gz
	./scripts/jags-compile.sh $(JAGSVERSION) vecLib single x86_64

tmp/JAGS-$(JAGSVERSION)-refBLAS-single-aarch64/.stamp: scripts/jags-compile.sh sources/JAGS-$(JAGSVERSION).tar.gz sources/pkg-config-$(PKGCONVERS).tar.gz sources/cppunit-$(CPPUNITVERS).tar.gz sources/v$(LAPACKVERS).tar.gz
	./scripts/jags-compile.sh $(JAGSVERSION) refBLAS single aarch64

tmp/JAGS-$(JAGSVERSION)-refBLAS-single-x86_64/.stamp: scripts/jags-compile.sh sources/JAGS-$(JAGSVERSION).tar.gz sources/pkg-config-$(PKGCONVERS).tar.gz sources/cppunit-$(CPPUNITVERS).tar.gz sources/v$(LAPACKVERS).tar.gz
	./scripts/jags-compile.sh $(JAGSVERSION) refBLAS single x86_64


## Lipo JAGS:  TODO: use % and $* like for tgz (jags-lipo will need to take two argumets only)

tmp/JAGS-$(JAGSVERSION)-refBLAS-single-universal/.stamp: scripts/jags-lipo.sh tmp/JAGS-$(JAGSVERSION)-refBLAS-single-aarch64/.stamp tmp/JAGS-$(JAGSVERSION)-refBLAS-single-x86_64/.stamp
	./scripts/jags-lipo.sh $(JAGSVERSION) refBLAS single

tmp/JAGS-$(JAGSVERSION)-vecLib-single-universal/.stamp: scripts/jags-lipo.sh tmp/JAGS-$(JAGSVERSION)-vecLib-single-aarch64/.stamp tmp/JAGS-$(JAGSVERSION)-vecLib-single-x86_64/.stamp
	./scripts/jags-lipo.sh $(JAGSVERSION) vecLib single

tmp/JAGS-$(JAGSVERSION)-vecLib-gcd-universal/.stamp: scripts/jags-lipo.sh tmp/JAGS-$(JAGSVERSION)-vecLib-gcd-aarch64/.stamp tmp/JAGS-$(JAGSVERSION)-vecLib-gcd-x86_64/.stamp
	./scripts/jags-lipo.sh $(JAGSVERSION) vecLib gcd


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

