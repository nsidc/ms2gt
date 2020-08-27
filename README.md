![NSIDC logo](/images/NSIDC_logo_2018_poster-1.png)

# MODIS Swath-to-Grid Toolkit

The MODIS Swath-to-Grid Toolbox (MS2GT) is a set of software tools that
can be used to read HDF-EOS files containing MODIS swath data and produce
flat binary files containing gridded data in a variety of map
projections. Multiple input files corresponding to successively acquired 5
minute MODIS "scenes" can be processed together to produce a seamless
output grid.

MS2GT consists of four perl programs that make calls to several
standalone IDL and C programs: mod02.pl which reads MOD02 Level 1b files,
mod10_l2.pl which reads MOD10_L2 snow cover files, mod29.pl which
reads MOD29 sea ice files, and mod35_l2 which reads MOD35_L2 cloud mask
files. All four Perl programs can optionally read MOD03 files for
geolocation and/or ancillary data.

## Level of Support

* This repository is not actively supported by NSIDC but we welcome issue submissions and pull requests in order to foster community contribution.

See the [LICENSE](LICENSE.md) for details on permissions and warranties. Please contact nsidc@nsidc.org for more information.

## Requirements

This package requires:
* C compiler (such as gcc)
* Perl
* IDL

## Installation

See ms2gt/documentation.md for information on how to build and install the toolkit.  Note that the documentation was written for v0.5 and have not been updated since.  Note that the documentation there refers to downloading the v0.5 package from the FTP site.  If using this repository, you do not need to do that, you can simply clone this repository into a folder and run the ms2gt/documentation.md#building step from there.

## Usage

See the tutorials for information on using the tools in the toolkit.  Note that these tutorials were written for v0.5, and have not been updated since.  Changes that apply to later versions may not be covered.

## License

See [LICENSE](LICENSE.md).

## Code of Conduct

See [Code of Conduct](CODE_OF_CONDUCT.md).

## Credit

This software was developed by the National Snow and Ice Data Center with funding from multiple sources.
