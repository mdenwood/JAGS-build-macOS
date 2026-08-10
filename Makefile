## Versions of JAGS, CPPUNIT and LAPACK to use
JAGSVERSION := 5.0.0
CPPUNITVERS = 1.15.1
LAPACKVERS = 3.12.1
PKGCONVERS = 0.29.2

## Extract JAGS major version from full version
VERSMAJ = $(word 1,$(subst ., ,$(JAGSVERSION)))


## Complete build
.PHONY: all
# all: tools tmp/JAGS-$(JAGSVERSION)-vecLib-single-x86_64/.stamp tmp/JAGS-$(JAGSVERSION)-vecLib-gcd-aarch64/.stamp tmp/JAGS-$(JAGSVERSION)-vecLib-gcd-x86_64/.stamp tmp/JAGS-$(JAGSVERSION)-vecLib-single-aarch64/.stamp tmp/JAGS-$(JAGSVERSION)-refBLAS-single-aarch64/.stamp tmp/JAGS-$(JAGSVERSION)-refBLAS-single-x86_64/.stamp
# all: build/JAGS-$(JAGSVERSION)-vecLib-gcd-universal.pkg
# all: tmp/JAGS-$(JAGSVERSION)-vecLib-single-universal/.stamp
all: build/JAGS-$(JAGSVERSION)-vecLib-gcd-aarch64.pkg

## Create folders

.PHONY: mkdirs
mkdirs: sources tmp lib build

sources:
	mkdir sources
tmp:
	mkdir tmp
lib:
	mkdir lib
build:
	mkdir build


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

sources/JAGS-$(JAGSVERSION).tar.gz: 
	curl -OL --output-dir sources https://sourceforge.net/projects/mcmc-jags/files/JAGS/$(VERSMAJ).x/Source/JAGS-$(JAGSVERSION).tar.gz
	
sources/v$(LAPACKVERS).tar.gz:
	curl -OL --output-dir sources https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v3.12.1.tar.gz
	
sources/cppunit-$(CPPUNITVERS).tar.gz: 
	curl -OL --output-dir sources http://dev-www.libreoffice.org/src/cppunit-$(CPPUNITVERS).tar.gz

sources/pkg-config-$(PKGCONVERS).tar.gz: 
	curl -OL --output-dir sources https://pkg-config.freedesktop.org/releases/pkg-config-$(PKGCONVERS).tar.gz
	

## Build tools

# TODO: move lib to tools and then replace .PHONY tools with tools/.stamp

.PHONY: tools
tools: lib/pkg-config/.stamp lib/cppunit/.stamp lib/lapack/.stamp

lib/pkg-config/.stamp: sources/pkg-config-$(PKGCONVERS).tar.gz
	./scripts/pkgconfig.sh $(PKGCONVERS)

lib/cppunit/.stamp: sources/cppunit-$(CPPUNITVERS).tar.gz
	./scripts/cppunit.sh $(CPPUNITVERS)

lib/lapack/.stamp: sources/v$(LAPACKVERS).tar.gz
	./scripts/lapack.sh $(LAPACKVERS)


## Compile JAGS

tmp/JAGS-$(JAGSVERSION)-vecLib-gcd-aarch64/.stamp: sources/JAGS-$(JAGSVERSION).tar.gz sources/pkg-config-$(PKGCONVERS).tar.gz sources/cppunit-$(CPPUNITVERS).tar.gz
	./scripts/jags-compile.sh $(JAGSVERSION) vecLib gcd aarch64

tmp/JAGS-$(JAGSVERSION)-vecLib-gcd-x86_64/.stamp: sources/JAGS-$(JAGSVERSION).tar.gz sources/pkg-config-$(PKGCONVERS).tar.gz sources/cppunit-$(CPPUNITVERS).tar.gz
	./scripts/jags-compile.sh $(JAGSVERSION) vecLib gcd x86_64

tmp/JAGS-$(JAGSVERSION)-vecLib-single-aarch64/.stamp: sources/JAGS-$(JAGSVERSION).tar.gz sources/pkg-config-$(PKGCONVERS).tar.gz sources/cppunit-$(CPPUNITVERS).tar.gz
	./scripts/jags-compile.sh $(JAGSVERSION) vecLib single aarch64

tmp/JAGS-$(JAGSVERSION)-vecLib-single-x86_64/.stamp: sources/JAGS-$(JAGSVERSION).tar.gz sources/pkg-config-$(PKGCONVERS).tar.gz sources/cppunit-$(CPPUNITVERS).tar.gz
	./scripts/jags-compile.sh $(JAGSVERSION) vecLib single x86_64

tmp/JAGS-$(JAGSVERSION)-refBLAS-single-aarch64/.stamp: sources/JAGS-$(JAGSVERSION).tar.gz sources/pkg-config-$(PKGCONVERS).tar.gz sources/cppunit-$(CPPUNITVERS).tar.gz sources/v$(LAPACKVERS).tar.gz
	./scripts/jags-compile.sh $(JAGSVERSION) refBLAS single aarch64

tmp/JAGS-$(JAGSVERSION)-refBLAS-single-x86_64/.stamp: sources/JAGS-$(JAGSVERSION).tar.gz sources/pkg-config-$(PKGCONVERS).tar.gz sources/cppunit-$(CPPUNITVERS).tar.gz sources/v$(LAPACKVERS).tar.gz
	./scripts/jags-compile.sh $(JAGSVERSION) refBLAS single x86_64


## Lipo JAGS

tmp/JAGS-$(JAGSVERSION)-refBLAS-single-universal/.stamp: tmp/JAGS-$(JAGSVERSION)-refBLAS-single-aarch64/.stamp tmp/JAGS-$(JAGSVERSION)-refBLAS-single-x86_64/.stamp
	./scripts/jags-lipo.sh $(JAGSVERSION) refBLAS single

tmp/JAGS-$(JAGSVERSION)-vecLib-single-universal/.stamp: tmp/JAGS-$(JAGSVERSION)-vecLib-single-aarch64/.stamp tmp/JAGS-$(JAGSVERSION)-vecLib-single-x86_64/.stamp
	./scripts/jags-lipo.sh $(JAGSVERSION) vecLib single

tmp/JAGS-$(JAGSVERSION)-vecLib-gcd-universal/.stamp: tmp/JAGS-$(JAGSVERSION)-vecLib-gcd-aarch64/.stamp tmp/JAGS-$(JAGSVERSION)-vecLib-gcd-x86_64/.stamp
	./scripts/jags-lipo.sh $(JAGSVERSION) vecLib gcd


## Create JAGS installers

build/JAGS-$(JAGSVERSION)-vecLib-gcd-aarch64.pkg: tmp/JAGS-$(JAGSVERSION)-vecLib-gcd-aarch64/.stamp
	./scripts/jags-package.sh $(JAGSVERSION) vecLib gcd aarch64

build/JAGS-$(JAGSVERSION)-vecLib-gcd-universal.pkg: tmp/JAGS-$(JAGSVERSION)-vecLib-gcd-aarch64/.stamp tmp/JAGS-$(JAGSVERSION)-vecLib-gcd-x86_64/.stamp
	./scripts/jags-package.sh $(JAGSVERSION) vecLib gcd universal
