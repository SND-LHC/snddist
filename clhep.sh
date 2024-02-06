package: CLHEP
version: "2.2.0.8"
source: https://gitlab.cern.ch/CLHEP/CLHEP.git
tag: CLHEP_2_2_0_8
build_requires:
  - CMake
  - "Xcode:(osx.*)"
---
#!/bin/sh
cmake "$SOURCEDIR"                                 \
      -DCMAKE_CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"

cmake --build . -- ${JOBS:+-j$JOBS} install

MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

cat >> "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
if ![ is-loaded 'BASE/1.0' ] {
 module load BASE/1.0
}

set PKG_ROOT $::env(BASEDIR)/CLHEP/$version
prepend-path LD_LIBRARY_PATH $PKG_ROOT/lib

# Our environment
set CLHEP_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$CLHEP_ROOT/lib
EoF
