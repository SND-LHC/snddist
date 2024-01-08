package: sndsw
version: master
source: https://github.com/SND-LHC/sndsw
tag: master
requires:
  - generators
  - simulation
  - FairRoot
  - FairLogger
  - GENIE
  - GEANT4
  - PHOTOSPP
  - EvtGen
  - ROOT
  - VMC
  - alpaca
  - FEDRA
  - XRootD
  - GenFit
incremental_recipe: |
  rsync -ar $SOURCEDIR/ $INSTALLROOT/
  make ${JOBS:+-j$JOBS}
  make test
  make install
  rsync -a $BUILDDIR/bin $INSTALLROOT/
  # to be sure all header files are there
  rsync -a $INSTALLROOT/*/*.h $INSTALLROOT/include
  rsync -a $INSTALLROOT/genfit/core/include/*.h $INSTALLROOT/include
  #Get the current git hash
  cd $SOURCEDIR
  SNDSW_HASH=$(git rev-parse HEAD)
  cd $BUILDDIR
  # Modulefile
  MODULEDIR="$INSTALLROOT/etc/modulefiles"
  MODULEFILE="$MODULEDIR/$PKGNAME"
  mkdir -p "$MODULEDIR"
  cat > "$MODULEFILE" <<EoF
  #%Module1.0
  proc ModulesHelp { } {
    global version
    puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
  }
  set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
  module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
  # Dependencies
  module load BASE/1.0                                                          \\
            ${XROOTD_VERSION:+XRootD/$XROOTD_VERSION-$XROOTD_REVISION}          \\
            ${GEANT4_VERSION:+GEANT4/$GEANT4_VERSION-$GEANT4_REVISION}          \\
            ${GENIE_VERSION:+GENIE/$GENIE_VERSION-$GENIE_REVISION}              \\
            ${PHOTOSPP_VERSION:+PHOTOSPP/$PHOTOSPP_VERSION-$PHOTOSPP_REVISION}  \\
            ${EVTGEN_VERSION:+EvtGen/$EVTGEN_VERSION-$EVTGEN_REVISION}          \\
            ${FAIRROOT_VERSION:+FairRoot/$FAIRROOT_VERSION-$FAIRROOT_REVISION}  \\
            ${MADGRAPH5_VERSION:+madgraph5/$MADGRAPH5_VERSION-$MADGRAPH5_REVISION} \\
            ${ALPACA_VERSION:+alpaca/$ALPACA_VERSION-$ALPACA_REVISION}          \\
            ${FEDRA_VERSION:+FEDRA/$FEDRA_VERSION-$FEDRA_REVISION}
  # Our environment
  setenv EOSSHIP root://eospublic.cern.ch/
  setenv SNDSW_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
  setenv FAIRSHIP \$::env(SNDSW_ROOT)
  setenv FAIRSHIP_ROOT \$::env(SNDSW_ROOT)
  setenv SNDSW_HASH $SNDSW_HASH
  setenv FAIRSHIP_HASH \$::env(SNDSW_HASH)
  setenv VMCWORKDIR \$::env(SNDSW_ROOT)
  setenv GEOMPATH \$::env(SNDSW_ROOT)/geometry
  setenv CONFIG_DIR \$::env(SNDSW_ROOT)/gconfig
  setenv GALGCONF \$::env(SNDSW_ROOT)/shipgen/genie_config
  prepend-path PATH \$::env(SNDSW_ROOT)/bin
  prepend-path LD_LIBRARY_PATH \$::env(SNDSW_ROOT)/lib
  setenv FAIRLIBDIR \$::env(SNDSW_ROOT)/lib
  prepend-path ROOT_INCLUDE_PATH \$::env(SNDSW_ROOT)/include
  append-path ROOT_INCLUDE_PATH \$::env(GEANT4_ROOT)/include
  append-path ROOT_INCLUDE_PATH \$::env(GEANT4_ROOT)/include/Geant4
  append-path ROOT_INCLUDE_PATH \$::env(PYTHIA_ROOT)/include
  append-path ROOT_INCLUDE_PATH \$::env(PYTHIA_ROOT)/include/Pythia8
  append-path ROOT_INCLUDE_PATH \$::env(GEANT4_VMC_ROOT)/include
  append-path ROOT_INCLUDE_PATH \$::env(GEANT4_VMC_ROOT)/include/geant4vmc
  append-path ROOT_INCLUDE_PATH \$::env(SNDSW_ROOT)/genfit/core/include
  append-path PYTHONPATH        \$::env(XROOTD_ROOT)/lib/python/site-packages
  # required for ubuntu22.04: don't know how to fix this more elegant
  append-path PYTHONPATH        \$::env(XROOTD_ROOT)/local/lib/python3.10/dist-packages

  append-path ROOT_INCLUDE_PATH \$::env(FEDRA_ROOT)/include
  append-path ROOT_INCLUDE_PATH \$::env(FEDRA_ROOT)/include/smatrix
  append-path ROOT_INCLUDE_PATH \$::env(FEDRA_ROOT)/include/vt++
  append-path ROOT_INCLUDE_PATH \$::env(FEDRA_ROOT)/include/dataIO
  append-path PYTHONPATH \$::env(FEDRA_ROOT)/python

  prepend-path PYTHONPATH \$::env(SNDSW_ROOT)/python
  append-path PYTHONPATH \$::env(SNDSW_ROOT)/shipLHC/scripts
  append-path PYTHONPATH \$::env(SNDSW_ROOT)/shipLHC/rawData
  $([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(SNDSW_ROOT)/lib")
  EoF
---
#!/bin/sh

# Making sure people do not have SIMPATH set when they build fairroot.
# Unfortunately SIMPATH seems to be hardcoded in a bunch of places in
# fairroot, so this really should be cleaned up in FairRoot itself for
# maximum safety.
unset SIMPATH

case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost`
    [[ ! $ZEROMQ_ROOT ]] && ZEROMQ_ROOT=`brew --prefix zeromq`
    [[ ! $PROTOBUF_ROOT ]] && PROTOBUF_ROOT=`brew --prefix protobuf`
    [[ ! $NANOMSG_ROOT ]] && NANOMSG_ROOT=`brew --prefix nanomsg`
    [[ ! $GSL_ROOT ]] && GSL_ROOT=`brew --prefix gsl`
    SONAME=dylib
  ;;
  *) SONAME=so ;;
esac
rsync -a $SOURCEDIR/ $INSTALLROOT/

cmake $SOURCEDIR                                                 \
      -DFAIRBASE="$FAIRROOT_ROOT/share/fairbase"                 \
      -DFAIRROOTPATH="$FAIRROOTPATH"                             \
      -DFAIRROOT_INCLUDE_DIR="$FAIRROOT_ROOT/include"            \
      -DFAIRROOT_LIBRARY_DIR="$FAIRROOT_ROOT/lib"                \
      -DFAIRLOGGER_INCLUDE_DIR="$FAIRLOGGER_ROOT/include"        \
      -DFMT_INCLUDE_DIR="$FMT_ROOT/include"                      \
      -DCMAKE_CXX_FLAGS="$CXXFLAGS"                              \
      -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE                       \
      -DROOTSYS=$ROOTSYS                                         \
      -DROOT_DIR=$ROOT_ROOT                                      \
      -DHEPMC_DIR=$HEPMC_ROOT                                    \
      -DHEPMC_INCLUDE_DIR=$HEPMC_ROOT/include/HepMC              \
      -DEVTGEN_INCLUDE_DIR=$EVTGEN_ROOT/include                  \
      -DEVTGEN_LIBRARY_DIR=$EVTGEN_ROOT/lib                      \
      ${PYTHON_ROOT:+-DPYTHON_LIBRARY=$PYTHON_ROOT/lib}          \
      ${PYTHON_ROOT:+-DPYTHON_INCLUDE_DIR=$PYTHON_ROOT/include/python3.6m/} \
      -DPYTHIA8_DIR=$PYTHIA_ROOT                                 \
      -DPYTHIA8_INCLUDE_DIR=$PYTHIA_ROOT/include                 \
      -DXROOTD_INCLUDE_DIR=$XROOTD_ROOT/include/xrootd           \
      -DGEANT4_ROOT=$GEANT4_ROOT                                 \
      -DGEANT4_INCLUDE_DIR=$GEANT4_ROOT/include/Geant4           \
      -DGEANT4_VMC_INCLUDE_DIR=$GEANT4_VMC_ROOT/include/geant4vmc \
      ${CMAKE_VERBOSE_MAKEFILE:+-DCMAKE_VERBOSE_MAKEFILE=ON}     \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                    \
      ${GENFIT:+-Dgenfit2_ROOT=$GENFIT} \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT
make ${JOBS:+-j$JOBS}
make test
make install

rsync -a $BUILDDIR/bin $INSTALLROOT/
# to be sure all header files are there
rsync -a $INSTALLROOT/*/*.h $INSTALLROOT/include
rsync -a $INSTALLROOT/genfit/core/include/*.h $INSTALLROOT/include

#Get the current git hash
cd $SOURCEDIR
SNDSW_HASH=$(git rev-parse HEAD)
cd $BUILDDIR

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0                                                            \\
            ${XROOTD_VERSION:+XRootD/$XROOTD_VERSION-$XROOTD_REVISION}          \\
            ${GEANT4_VERSION:+GEANT4/$GEANT4_VERSION-$GEANT4_REVISION}          \\
            ${GENIE_VERSION:+GENIE/$GENIE_VERSION-$GENIE_REVISION}              \\
            ${PHOTOSPP_VERSION:+PHOTOSPP/$PHOTOSPP_VERSION-$PHOTOSPP_REVISION}  \\
            ${EVTGEN_VERSION:+EvtGen/$EVTGEN_VERSION-$EVTGEN_REVISION}          \\
            ${FAIRROOT_VERSION:+FairRoot/$FAIRROOT_VERSION-$FAIRROOT_REVISION}	\\
            ${MADGRAPH5_VERSION:+madgraph5/$MADGRAPH5_VERSION-$MADGRAPH5_REVISION} \\
            ${ALPACA_VERSION:+alpaca/$ALPACA_VERSION-$ALPACA_REVISION}          \\
            ${FEDRA_VERSION:+FEDRA/$FEDRA_VERSION-$FEDRA_REVISION}
# Our environment
setenv EOSSHIP root://eospublic.cern.ch/
setenv SNDSW_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv FAIRSHIP \$::env(SNDSW_ROOT)
setenv FAIRSHIP_ROOT \$::env(SNDSW_ROOT)
setenv SNDSW_HASH $SNDSW_HASH
setenv FAIRSHIP_HASH \$::env(SNDSW_HASH)
setenv VMCWORKDIR \$::env(SNDSW_ROOT)
setenv GEOMPATH \$::env(SNDSW_ROOT)/geometry
setenv CONFIG_DIR \$::env(SNDSW_ROOT)/gconfig
setenv GALGCONF \$::env(SNDSW_ROOT)/shipgen/genie_config
prepend-path PATH \$::env(SNDSW_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(SNDSW_ROOT)/lib
setenv FAIRLIBDIR \$::env(SNDSW_ROOT)/lib
prepend-path ROOT_INCLUDE_PATH \$::env(SNDSW_ROOT)/include
append-path ROOT_INCLUDE_PATH \$::env(GEANT4_ROOT)/include
append-path ROOT_INCLUDE_PATH \$::env(GEANT4_ROOT)/include/Geant4
append-path ROOT_INCLUDE_PATH \$::env(PYTHIA_ROOT)/include
append-path ROOT_INCLUDE_PATH \$::env(PYTHIA_ROOT)/include/Pythia8
append-path ROOT_INCLUDE_PATH \$::env(GEANT4_VMC_ROOT)/include
append-path ROOT_INCLUDE_PATH \$::env(GEANT4_VMC_ROOT)/include/geant4vmc
prepend-path PYTHONPATH \$::env(SNDSW_ROOT)/python
append-path PYTHONPATH \$::env(SNDSW_ROOT)/shipLHC/scripts
append-path PYTHONPATH \$::env(SNDSW_ROOT)/shipLHC/rawData
append-path PYTHONPATH \$::env(XROOTD_ROOT)/lib/python/site-packages
# required for ubuntu22.04: don't know how to fix this more elegant
append-path PYTHONPATH  \$::env(XROOTD_ROOT)/local/lib/python3.10/dist-packages

append-path ROOT_INCLUDE_PATH \$::env(FEDRA_ROOT)/include
append-path ROOT_INCLUDE_PATH \$::env(FEDRA_ROOT)/include/smatrix
append-path ROOT_INCLUDE_PATH \$::env(FEDRA_ROOT)/include/vt++
append-path ROOT_INCLUDE_PATH \$::env(FEDRA_ROOT)/include/dataIO
append-path PYTHONPATH \$::env(FEDRA_ROOT)/python

$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(SNDSW_ROOT)/lib")
EoF
