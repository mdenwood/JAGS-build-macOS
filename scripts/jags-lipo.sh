#!/bin/zsh

# SPDX-FileCopyrightText: 2026 Matthew Denwood (https://github.com/mdenwood/JAGS-build-macOS)
# SPDX-License-Identifier: Apache-2.0

# Abort on error, use of unset variable, or error within pipe:
set -euo pipefail

# Return codes:
EX_OK=0
EX_USAGE=64
EX_CONFIG=78

# Note: this script is intended to be run from the root directory (by the Makefile)
./scripts/check_deps.sh

## Check arguments
if [ "$#" -ne 2 ]; then
    echo "Error: 2 arguments required (got $#)."
    echo "Usage: $0 <VERSION> <BLAS-THREAD>"
    exit $EX_USAGE
fi

VERSION="$1"
BUILD="$2"
BUILDELEMS=( ${(s:-:)BUILD} )
BLAS=$BUILDELEMS[1]
THREAD=$BUILDELEMS[2]

# Extract major version
VERSMAJ=$(echo $VERSION | cut -d "." -f 1)
if [ ! "$VERSION" -ge 4 ] 2>/dev/null; then
  echo "JAGS version 4.x.y or greater required" 1>&2
  exit $EX_USAGE
fi

# Check that the blas is valid:
if [[ "$BLAS" == "vecLib" ]]; then
  # Do nothing
elif [[ "$BLAS" == "accelerate" ]]; then
  BLAS="vecLib"
elif [[ "$BLAS" == "Accelerate" ]]; then
  BLAS="vecLib"
elif [[ "$BLAS" == "apple" ]]; then
  BLAS="vecLib"
elif [[ "$BLAS" == "refBLAS" ]]; then
  # Do nothing
elif [[ "$BLAS" == "lapack" ]]; then
  BLAS="refBLAS"
elif [[ "$BLAS" == "ref" ]]; then
  BLAS="refBLAS"
elif [[ "$BLAS" == "netlib" ]]; then
  BLAS="refBLAS"
elif [[ "$BLAS" == "Netlib" ]]; then
  BLAS="refBLAS"
else
  echo "Invalid BLAS specified" 1>&2
  exit $EX_USAGE
fi  

# Check that the multi-threading option is valid:
if [[ "$THREAD" == "gcd" ]]; then
  # Do nothing
elif [[ "$THREAD" == "GCD" ]]; then
  THREAD="gcd"
elif [[ "$THREAD" == "openmp" ]]; then
  # TODO: add OpenMP support by downloading/bundling the OpenMP run time from https://mac.r-project.org/openmp/ with jags-terminal only and compiling rjags with -fopenmp
  # Note: rjags will probably need re-compiling after switching to openmp build using jags-version ???
  echo "Compiling against OpenMP is not yet supported" 1>&2
  exit $EX_USAGE
elif [[ "$THREAD" == "single" ]]; then
  # Do nothing
elif [[ "$THREAD" == "st" ]]; then
  THREAD="single"
else
  echo "Invalid THREAD specified" 1>&2
  exit $EX_USAGE
fi  

rm -rf "tmp/JAGS-$VERSION-$BLAS-$THREAD-universal"
mkdir -p "tmp/JAGS-$VERSION-$BLAS-$THREAD-universal/opt/jags/versions/jags/$VERSION-$BLAS-$THREAD-universal/"
cp -r "tmp/JAGS-$VERSION-$BLAS-$THREAD-aarch64/opt/jags/versions/jags/$VERSION-$BLAS-$THREAD-aarch64/" "tmp/JAGS-$VERSION-$BLAS-$THREAD-universal/opt/jags/versions/jags/$VERSION-$BLAS-$THREAD-universal/"
cd "tmp/JAGS-$VERSION-$BLAS-$THREAD-universal"

for dd in $(find "opt" -type d -print); do
  dx=$(echo $dd | sed 's/universal/x86_64/')
  for ff in $(ls "$dd"); do
    ftype=$(file -I "$dd/$ff")
    # If a binary:
    if echo "$ftype" | grep -q "application/x-mach-binary"; then
      # That isn't a symlink:
      if test ! -L "$dd/$ff"; then
        # Stitch together:
      	lipo "$dd/$ff" "../JAGS-$VERSION-$BLAS-$THREAD-x86_64/$dx/$ff" -create -output "$dd/$ff"
      fi
    fi
  done
done

## Convert the jags, pkg-config and man files to say universal:
sed -i '' "s/aarch64/universal/g" "opt/jags/versions/jags/$VERSION-$BLAS-$THREAD-universal/bin/jags"
sed -i '' "s/aarch64/universal/g" "opt/jags/versions/jags/$VERSION-$BLAS-$THREAD-universal/lib/pkgconfig/jags.pc"
sed -i '' "s/aarch64/universal/g" "opt/jags/versions/jags/$VERSION-$BLAS-$THREAD-universal/share/man/man1/jags.1"

echo "This doesn't work:  Library not loaded: /opt/jags/versions/jags/5.0.0-vecLib-single-aarch64/lib/libjags.5.dylib;  Referenced from: <C0356027-6388-32AA-A817-184A196DF9A8> /opt/jags/versions/jags/5.0.0-vecLib-single-universal/libexec/jags-terminal"
exit 1

touch ".stamp"

exit $EX_OK
