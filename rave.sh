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
---
cd $SOURCEDIR

cp -R "$CLHEP_ROOT/include/CLHEP" "$SOURCEDIR" # TODO fix CLHEP headers not being found

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

alibuild-generate-module --lib > $MODULEFILE

cat >> "$MODULEFILE" <<EoF
# Our environment
set RAVE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv RAVEPATH \$RAVE_ROOT
EoF
