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

_(Choose one of the following bullets to describe USO Level of Support, then delete this instructional message along with the unchosen support bullet)_

* This repository is fully supported by NSIDC. If you discover any problems or bugs, please submit an Issue. If you would like to contribute to this repository, you may fork the repository and submit a pull request.
* This repository is not actively supported by NSIDC but we welcome issue submissions and pull requests in order to foster community contribution.

See the [LICENSE](LICENSE) for details on permissions and warranties. Please contact nsidc@nsidc.org for more information.

## Requirements

This package requires:
* library 1.2.3

## Installation

Describe how to install the MyRepository, with platform-specific instructions if necessary.

## Usage

Describe how to use the MyRepository application/tool, with platform-specific instructions if necessary.

## Troubleshooting

Describe any tips or tricks in case the user runs into problems.

## License

See [LICENSE](LICENSE).

## Code of Conduct

See [Code of Conduct](CODE_OF_CONDUCT.md).

## Credit

This software was developed by the National Snow and Ice Data Center with funding from multiple sources.
