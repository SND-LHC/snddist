package: RAVE
version: 48873e5ec3e531183cbb64dd8bf4b31bbb7c24dd
source: https://github.com/olantwin/rave
requires:
  - boost
  - CLHEP
build-requires:
  - autotools
  - "GCC-Toolchain:(?!osx)"
env:
  RAVEPATH: "$RAVE_ROOT"
prepend_path:
  LD_LIBRARY_PATH: "$RAVEPATH/lib"
---
cd $SOURCEDIR

./bootstrap

./configure --with-boost="$BOOST_ROOT" \
	--with-clhep="$CLHEP_ROOT" \
	--disable-java \
	--prefix="$INSTALLROOT"

make clean

make -j$JOBS

make install 

mv "$SOURCEDIR"/RaveConfig.cmake "$INSTALLROOT"

# Modulefile
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
if ![ is-loaded "CLHEP/$CLHEP_VERSION-$CLHEP_REVISION" ] { module load "CLHEP/$CLHEP_VERSION-$CLHEP_REVISION"}

set PKG_ROOT $::env(BASEDIR)/RAVE/\$version
prepend-path LD_LIBRARY_PATH \$PKG_ROOT/lib

# Our environment
set RAVE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv RAVEPATH \$RAVE_ROOT
EoF
