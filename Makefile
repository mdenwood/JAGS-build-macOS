## Versions of JAGS, CPPUNIT and LAPACK to use
VERSION = 5.0.0
CPPUNITVERS = 1.15.1
LAPACKVERS = 3.12.1

## Extract JAGS major version from full version
VERSMAJ = $(word 1,$(subst ., ,$(VERSION)))


## Complete build
.PHONY: all
all:
	./scripts/cppunit.sh $(CPPUNITVERS)


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
download: mkdirs download-jags download-lapack download-cppunit

.PHONY: download-jags
download-jags: sources sources/JAGS-$(VERSION).tar.gz

.PHONY: download-lapack
download-lapack: sources sources/v$(LAPACKVERS).tar.gz

.PHONY: download-cppunit
download-cppunit: sources sources/cppunit-$(CPPUNITVERS).tar.gz

sources/JAGS-$(VERSION).tar.gz: 
	curl -OL --output-dir sources https://sourceforge.net/projects/mcmc-jags/files/JAGS/$(VERSMAJ).x/Source/JAGS-$(VERSION).tar.gz
	
sources/v$(LAPACKVERS).tar.gz:
	curl -OL --output-dir sources https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v3.12.1.tar.gz
	
sources/cppunit-$(CPPUNITVERS).tar.gz: 
	curl -OL --output-dir sources http://dev-www.libreoffice.org/src/cppunit-$(CPPUNITVERS).tar.gz


## Build cppunit

.PHONY: cppunit
cppunit: lib/cppunit

lib/cppunit:
	./scripts/cppunit.sh


## Build lapack
