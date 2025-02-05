# Changelog

All notable changes to this project will be documented in this file.
The latest changes are placed on top.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to (sort of) Calendar Versioning (year.month.day) as do our 
CVMFS releases. 

There could be several types of changes:
- `Added` for new features.
- `Changed` for changes in existing functionality.
- `Deprecated` for soon-to-be removed features.
- `Removed` for now removed features.
- `Fixed` for any bug fixes.
- `Security` in case of vulnerabilities.

For now we start with the changes introduced with the 2025/Jan30. 
Shall there be a strong will/need, one can go back and create&fill in the logs for previous stacks.

## 2025/Jan30

### Added

- CHANGELOG
- pandas python module
- POWHEG tune for forward charm and bottom production
- NNPDF31sx_nlonllx_as_0118_LHCb LHAPDF, needed for the forward tune above
- looptools package (fastjet->POWHEG required package)

### Changed

- Breaking change: FairROOT v19.0.0
- Bump FairMQ v1.9.1
- Bump to ROOT v6.28.12
- Bump Tauola to v1.1.8 
- Bump HepMC3 to v3.3.0
- Change cgal recipe as per L.Rottoli instructions [here](https://github.com/lucarottoli/forward_heavy_hadrons_NLONLLx/tree/main/POWHEG_configuration#readme) 

### Fixed

- ROOT recipe to be able to build on a machine <8GB RAM
- cmake policy for vmc, vgm, genat3 and geant4_vmc
