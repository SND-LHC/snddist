package: POWHEG
version: "%(tag_basename)s"
source: https://github.com/SND-LHC/POWHEG
tag: "r4110-forward-snd"
requires:
  - fastjet
  - "GCC-Toolchain:(?!osx|slc5)"
  - lhapdf
  - looptools
---
#!/bin/bash -e

rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./

install -d ${INSTALLROOT}/bin

export LIBRARY_PATH="$LD_LIBRARY_PATH"

PROCESSES="${FASTJET_VERSION:+trijet }${FASTJET_VERSION:+dijet }hvq W Z directphoton"
for proc in ${PROCESSES}; do
    mkdir ${proc}/{obj,obj-gfortran}
    make -C ${proc}
    install ${proc}/pwhg_main ${INSTALLROOT}/bin/pwhg_main_${proc}
done

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF

# Our environment
setenv POWHEG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv Powheg_INSTALL_PATH \$::env(POWHEG_ROOT)/lib/Powheg
setenv POWHEG_HVQ  \$::env(POWHEG_ROOT)/POWHEG/hvq
prepend-path PATH \$::env(POWHEG_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(POWHEG_ROOT)/lib/Powheg
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
