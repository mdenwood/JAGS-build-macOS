## Versions of JAGS, CPPUNIT and LAPACK to use
JAGSVERSION := 5.0.0
CPPUNITVERS = 1.15.1
LAPACKVERS = 3.12.1
PKGCONVERS = 0.29.2

## Extract JAGS major version from full version
VERSMAJ = $(word 1,$(subst ., ,$(JAGSVERSION)))


## Complete build
.PHONY: all
all: tools


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

.PHONY: tools
tools: download-pkgconfig lib/pkg-config download-cppunit lib/cppunit download-lapack lib/lapack

lib/pkg-config:
	./scripts/pkgconfig.sh $(PKGCONVERS)

lib/cppunit:
	./scripts/cppunit.sh $(CPPUNITVERS)

lib/lapack:
	./scripts/lapack.sh $(LAPACKVERS)


## JAGS builds

build/$(VERSION)-vecLib-gcd-aarch64:
	./scripts/jags.sh $(VERSION) vecLib gcd aarch64

