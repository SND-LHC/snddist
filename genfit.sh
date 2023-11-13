package: GenFit
version: 0a1ed8c
source: https://github.com/olantwin/GenFit
requires:
  - ROOT
  - RAVE
  - googletest # should be build dep?
  - boost
build-requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
env:
  GENFIT: "$GENFIT_ROOT"
prepend_path:
  ROOT_INCLUDE_PATH: "$GENFIT_ROOT/include"
  LD_LIBRARY_PATH: "$GENFIT_ROOT/lib"
---
cmake $SOURCEDIR                                                                            \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                                             \
      ${MACOSX_RPATH:+-DMACOSX_RPATH=${MACOSX_RPATH}}                                       \
      -DCMAKE_CXX_FLAGS="$CXXFLAGS"                                                         \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}                             \
      -DGTEST_ROOT=$GOOGLETEST_ROOT \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                                               \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON                                                    \
      -DCMAKE_INSTALL_LIBDIR=lib                                                            \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

cmake --build . -- -j$JOBS install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

alibuild-generate-module --bin --lib > $MODULEFILE

cat >> "$MODULEFILE" <<EoF
# Our environment
set GENFIT_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv GENFIT \$GENFIT_ROOT
prepend-path LD_LIBRARY_PATH \$GENFIT_ROOT/lib
prepend-path ROOT_INCLUDE_PATH \$GENFIT_ROOT/include
EoF
