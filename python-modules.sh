package: Python-modules
version: "1.0"
requires:
  - Python
  - FreeType
  - libpng
build_requires:
  - curl
prepend_path:
  PYTHONPATH: $PYTHON_MODULES_ROOT/lib/python$PYVSN/site-packages:$PYTHONPATH
prefer_system: (?!slc5)
prefer_system_check: |
  python3 -c 'import wheel, matplotlib,numpy,scipy,certifi,IPython,ipywidgets,ipykernel,notebook.notebookapp,metakernel,sklearn,six,pymongo,mongoengine,pytest,pylint,yaml'
  if [ $? -ne 0 ]
  then
      printf "Required Python modules are missing. You can install them with pip3:\n  pip3 install matplotlib numpy scipy certifi ipython ipywidgets ipykernel notebook metakernel scikit-learn six pymongo mongoengine pytest pylint pyyaml\n"
      exit 1
  fi
---
#!/bin/bash -ex

if [[ ! $PYTHON_VERSION ]]; then
  cat <<EoF
Building our own Python modules.
If you want to avoid this please install the following modules (pip recommended):

  - matplotlib
  - numpy
  - certifi
  - ipython
  - ipywidgets
  - ipykernel
  - notebook
  - metakernel
  - scipy
  - scikit-learn
  - six
  - mock
  - future
  - pymongo
  - mongoengine
  - pytest
  - pylint
  - pyyaml
  - psutil
EoF
fi

# Force pip installation of packages found in current PYTHONPATH
unset PYTHONPATH

# The X.Y in pythonX.Y
export PYVER=$(python3 -c 'import distutils.sysconfig; print(distutils.sysconfig.get_python_version())')

# Install as much as possible with pip. Packages are installed one by one as we
# are not sure that pip exits with nonzero in case one of the packages failed.
export PYTHONUSERBASE=$INSTALLROOT
python3 -m pip install --upgrade pip

# Install setuptools upfront, since this seems to create issues now...
python3 -m pip install -IU "setuptools < 60.0"
python3 -m pip install -IU wheel
python3 -m pip install -IU numpy

for X in "mock==1.3.0"          \
         "certifi==2019.6.16"   \
         "ipython==5.8.0"       \
         "ipywidgets==5.2.3"    \
         "ipykernel==4.10.0"    \
         "notebook==4.4.1"      \
         "metakernel==0.24.2"   \
         "scipy==1.6.1"         \
         "scikit-learn==0.24.1" \
         "matplotlib==3.5.1"    \
         "six"                  \
         "future"               \
         "pymongo==3.10.1"      \
         "pytest==4.6.9"        \
         "pylint==2.0.1"        \
         "PyYAML==5.1"          \
         "psutil==5.9.4"       \
         "requests==2.25.0"     \
         "mongoengine==0.23.1"
do
  python3 -m pip install --user $X
done

# for some unknown reason lib directory created with access only for user
chmod -R 755 $PYTHONUSERBASE/lib
unset PYTHONUSERBASE

# Test if matplotlib can be loaded
env PYTHONPATH="$INSTALLROOT/lib/python$PYVER/site-packages" python3 -c 'import matplotlib'

# Remove unneeded stuff
rm -rvf $INSTALLROOT/share            \
        $INSTALLROOT/lib/python*/test
find $INSTALLROOT/lib/python*                                              \
     -mindepth 2 -maxdepth 2 -type d -and \( -name test -or -name tests \) \
     -exec rm -rvf '{}' \;

# Fix shebangs to point to the correct Python from the runtime environment
grep -IlRE '#!.*python' $INSTALLROOT/bin | \
  xargs -n1 perl -p -i -e 's|^#!.*/python|#!/usr/bin/env python|'

# Test whether we can load Python modules (this is not obvious as some of them
# do not indicate some of their dependencies and break at runtime).
PYTHONPATH=$INSTALLROOT/lib64/python$PYVER/site-packages:$INSTALLROOT/lib/python$PYVER/site-packages:$PYTHONPATH \
  python3 -c 'import matplotlib,numpy,scipy,certifi,IPython,ipywidgets,ipykernel,notebook.notebookapp,metakernel,sklearn,six,pymongo,mongoengine,pytest,pylint'

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
module load BASE/1.0 ${PYTHON_VERSION:+Python/$PYTHON_VERSION-$PYTHON_REVISION} ${ALIEN_RUNTIME_VERSION:+AliEn-Runtime/$ALIEN_RUNTIME_VERSION-$ALIEN_RUNTIME_REVISION}
# Our environment
setenv PYVSN $PYVER
setenv PYTHON_MODULES_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH $::env(PYTHON_MODULES_ROOT)/bin
prepend-path LD_LIBRARY_PATH $::env(PYTHON_MODULES_ROOT)/lib64
prepend-path LD_LIBRARY_PATH $::env(PYTHON_MODULES_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH $::env(PYTHON_MODULES_ROOT)/lib64" && \
                                      echo "prepend-path DYLD_LIBRARY_PATH $::env(PYTHON_MODULES_ROOT)/lib")
prepend-path PYTHONPATH $::env(PYTHON_MODULES_ROOT)/lib/python$PYVER/site-packages
EoF
