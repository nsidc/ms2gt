## MS2GT: The MODIS Swath-to-Grid Toolbox

<div align="center" class="SmallText">*** Documentation for this product is in development and only covers through v0.5. *** </div>

* * *

*   [Version History](#history)
    *   [Version 0.5](#version_0.5)
    *   [Version 0.4](#version_0.4)
    *   [Version 0.3](#version_0.3)
    *   [Version 0.2](#version_0.2)
    *   [Version 0.1](#version_0.1)
    *   [Version 00.00](#version_00.00)
*   [Overview](#overview)
    *   [What the Software Does](#what)
    *   [How the Software Works](#how)
    *   [Requirements](#requirements)
    *   [Supported Data Sets](#datasets)
*   [Installation Instructions](#installation)
    *   [Obtaining the Software](#obtaining)
    *   [Building the Executables](#building)
    *   [Verifying your Perl Installation](#perl)
    *   [Setting up the MS2GT Environment](#environment)
    *   [Verifying the MS2GT Installation](#verifying)
*   [Using the MS2GT Software](#using)
    *   [Searching for the Data](#searching)
    *   [Ordering and Downloading the Data](#ordering)
    *   [Creating a MS2GT Command File](#command)
    *   [Creating Miscellaneous Text Files](#miscellaneous)
    *   [Running the MS2GT Command File](#running)
    *   [Examining the Results](#examining)
    *   [Geolocating the Results](#geolocating)
*   [Script Descriptions and Usage](#descriptions)
    *   [mod02.pl](#mod02)
    *   [mod10_l2.pl](#mod10_l2)
    *   [mod29.pl](#mod29)
*   [Tutorials](tutorials.md)

## <a name="history"></a>Version History

### <a name="version_0.5"></a>The current version of MS2GT is 0.5 released May 31, 2001

*   Changed perl location from /usr/local/bin/perl to /usr/bin/perl in idl_sh.pl.
*   Added exit(EXIT_SUCCESS) for successful exit from gridsize.c, ll2cr.c, and fornav.c to get around apparent Linux problem.
*   Moved mod10_l2.pl and mod29.pl usage descriptions into separate files.
*   Added [Script Descriptions and Usage](#descriptions).

### <a name="version_0.4"></a>Version 0.4 released May 3, 2001

*   Fixed bugs in fornav related to fill value processing.
*   Enhanced modis_ice_read.pro to allow processing by [mod29.pl](#mod29) of "dark" MOD29 granules which do not include Sea Ice by Reflectance, Sea Ice by Reflectance PixelQA, nor Combined Sea Ice channels. Gridded arrays containing the fill value of 255 are now returned when these channels are specified for dark MOD29 granules.
*   Modified [Building the Executables](#building) so that the make is run from the ms2gt/src directory rather than the ms2gt directory due to an unresolved problem on Linux platforms.

### <a name="version_0.3"></a>Version 0.3 released May 1, 2001

*   Fixed bug in [mod29.pl](#mod29) related to checking for a temperature channel.
*   Changed [mod29.pl](#mod29) mnemonics for better consistency.
*   Added -F option to ll2cr to allow specification of input and output fill values.
*   Added -r option to fornav to allow specification of a column-row fill value.
*   Added [Tutorial 4](tutorial_4.md).

### <a name="version_0.2"></a>Version 0.2 released April 27, 2001

*   Changed perl location from /usr/local/bin/perl to /usr/bin/perl.
*   Added [Verifying your Perl Installation](#perl).
*   Added [Tutorial 3](tutorial_3.md).
*   Fixed bugs in [mod10_l2.pl](#mod10_l2) and [mod29.pl](#mod29) related to reading the `*.gpd` file.
*   Changed channel numbers to mnemonic strings in output filenames for [mod10_l2.pl](#mod10_l2) and [mod29.pl](#mod29).

### <a name="version_0.1"></a>Version 0.1 released April 23, 2001

*   Added [Tutorial 2](tutorial_2.md).
*   Changed the -d weight_distance_max parameter to fornav from its default value of 1.0 to 1.2 due to the appearance of holes in a preliminary version of the [Tutorial 2](tutorial_2.md) example. Holes do not now appear to be a problem in this example.

### <a name="version_00.00"></a>Version 00.00 released April 20, 2001

*   Initial version.

## <a name="overview"></a>Overview

### <a name="what"></a>What the Software Does

The MODIS Swath-to-Grid Toolbox (MS2GT) is a set of software tools that can be used to read HDF-EOS files containing MODIS swath data and produce flat binary files containing gridded data in a variety of map projections. Multiple input files corresponding to successively acquired 5 minute MODIS "scenes" can be processed together to produce a seamless output grid.

MS2GT consists of three perl programs that make calls to several standalone IDL and C programs: [mod02.pl](#mod02) which reads [MOD021KM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD021KM.shtml), [MOD02HKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02HKM.shtml), or [MOD02QKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02QKM.shtml) Level 1b files, [mod10_l2.pl](#mod10_l2) which reads [MOD10_L2](/data/mod10_l2.html) snow cover files, and [mod29.pl](#mod29) which reads [MOD29](/data/mod29.html) sea ice files.  All three Perl programs can optionally read [MOD03](http://daac.gsfc.nasa.gov/CAMPAIGN_DOCS/MODIS/rad_geo/MOD03.shtml) files for geolocation information; in addition, [mod02.pl](#mod02) can extract "ancillary" data (such as illumination and viewing angles) from [MOD03](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD03.shtml) files.

### <a name="how"></a>How the Software Works

Each of the three Perl scripts provided with MS2GT make similar calls to the IDL and C programs outlined below:

*   User-specified swath data arrays are read out of HDF-EOS files using a suite of IDL programs written by [Liam Gumley](http://cimss.ssec.wisc.edu/~gumley/) of [SSEC at the University of Wisconsin](http://www.ssec.wisc.edu/). During this step, radiance data can be left as raw integer counts or converted to floating-point corrected counts, radiances, or reflectances; similarly, thermal data can be left as raw counts or converted to temperatures. These swath data arrays, including latitude and longitude arrays, are saved as temporary data files.
*   The latitude and longitude files are then converted to files containing column and row numbers of the target grid by a C program called ll2cr which uses the mapx C library written by Ken Knowles of NSIDC. The mapx library requires the use of a user-supplied [Grid Parameters Definition](github.com/nsidc/mapx/blob/master/PPGC.md#gpd) (gpd) text file that specifies the desired grid and associated map projection.
*   The column and row files and any ancillary data files are then interpolated to the resolution of the primary data files (1 km for [MOD021KM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD021KM.shtml) and [MOD29](/data/mod29.html), 500 m for [MOD02HKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02HKM.shtml) and [MOD10_L2](/data/mod10_l2.html), or 250 m for [MOD02QKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02QKM.shtml)) as necessary using two IDL programs (interp_colrow.pro and interp_swath.pro).
*   Finally, the interpolated column and row files, together with the primary data files and any interpolated ancillary data files are run through a C program called fornav that performs forward navigation to produce gridded flat binary files. The user can specify that either elliptical weighted averaging or elliptical maximum weight sampling be used during forward navigation.

 It should relatively easy for a user who is familiar with Perl and IDL programming to modify the Perl scripts and IDL procedures in order to process other kinds swath data using many of the same standalone programs provided with MS2GT. Further details can be found in the [Tutorials](tutorials.md).

### <a name="requirements"></a>Requirements

In its current form, MS2GT runs on a Unix workstation with a standard C compiler. It also requires Perl 5.0 or higher and IDL 5.0 or higher. The installation instructions assume that the user is running csh or tcsh as the Unix shell. Users of other shells (e.g. bash, ksh, sh, etc.) may have to make slight changes to the installation instructions.

MS2GT has been developed and tested on an SGI O2 workstation having 192 Mbytes of memory and running IRIX 6.5, perl 5.004_04, and IDL 5.4. Care has been taken to minimize memory requirements at the expense of increased temporary disk storage requirements and slightly slower speed. However, in its current form, MS2GT does require that two times a grid's worth of single precision floating-point data for one channel fit into virtual memory. The result is that fairly large gridded images can be created on a machine with a modest amount of memory in a fairly short time. For example, the creation of two 1316 x 1384 250 m grids containing MODIS channels 1 and 2 reflectance data derived from a single [MOD02QKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02QKM.shtml) file takes about three minutes on the above machine and requires about 2 * 1316 * 1384 * 4 = 15 MB of free virtual memory.  
  

### <a name="datasets"></a>Supported Data Sets

See the [MODIS Home Page](http://modis.gsfc.nasa.gov/) for general information on the MODIS instrument. See [MODIS Snow and Ice Products](/data/modis/) for information on MODIS snow and ice products distributed by NSIDC.

<table border="1" width="100%">

<tbody>

<tr>
<td>Short Name</td>
<td>Long Name</td>
<td>Channel Data</td>
<td>Ancillary</td>
<td>Lat-lon</td>
</tr>

<tr>
<td nosave="">[MOD021KM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD021KM.shtml)</td>
<td>MODIS/TERRA CALIBRATED RADIANCES 5-MIN L1B SWATH 1KM</td>
<td>1-36 @ 1 km</td>
<td>7 @ 5 km</td>
<td>5 km</td>
</tr>

<tr>
<td nosave="">[MOD02HKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02HKM.shtml)</td>
<td>MODIS/TERRA CALIBRATED RADIANCES 5-MIN L1B SWATH 500M</td>
<td>1-7 @ 500 m</td>
<td>none</td>
<td>1 km</td>
</tr>

<tr>
<td>[MOD02QKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02QKM.shtml)</td>
<td>MODIS/TERRA CALIBRATED RADIANCES 5-MIN L1B SWATH 250M</td>
<td>1-2 @ 250 m</td>
<td>none</td>
<td>1 km</td>
</tr>

<tr>
<td>[MOD03](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD03.shtml)</td>
<td>MODIS/TERRA GEOLOCATION FIELDS 5-MIN L1A SWATH 1KM</td>
<td>none</td>
<td>8 @ 1 km</td>
<td>1 km</td>
</tr>

<tr>
<td>[MOD10_L2](/data/mod10_l2.html)</td>
<td>MODIS/TERRA SNOW COVER 5-MIN L2 SWATH 500M</td>
<td>2 @ 500 m</td>
<td>none</td>
<td>5 km</td>
</tr>

<tr>
<td>[MOD29](/data/mod29.html)</td>
<td>MODIS/TERRA SEA ICE EXTENT 5-MIN L2 SWATH 1KM</td>
<td>6 @ 1 km</td>
<td>none</td>
<td>5 km</td>
</tr>

</tbody>
</table>

## <a name="installation"></a>Installation Instructions

### <a name="obtaining"></a>Obtaining the Software

The software and associated documentation can be downloaded from this repository.  Clone this repository into some directory where you want the MS2GT software installed. It is recommended you do not clone this repository into the same directory where a previous version may have been installed.  The easiest way is to go to the directory you want to be the main directory and type:

`git clone git@github.com/nsidc/ms2gt.git`

This will create a directory in the current directory called ms2gt which will contain several subdirectories. Further instructions on the installation and use of MS2GT can be found in the [doc](../doc/) directory of
this repository.

### <a name="building"></a>Building the Executables

Change the current working directory to the ms2gt/src directory and type:

`make all`

This will build and install the MS2GT executables under the ms2gt directory. The only write privileges required are the ability to write into the ms2gt directory and its subdirectories.

### <a name="perl"></a>Verifying your Perl Installation

Type the command:

`perl -v`

If you see something like:

```
This is perl, version 5.004_04 built for irix-n32

Copyright 1987-1997, Larry Wall

Perl may be copied only under the terms of either the Artistic License or the
GNU General Public License, which may be found in the Perl 5.0 source kit.
```

then you know perl has been installed ok. Just make sure you have at least perl version 5 installed. However, if you see something like:

`perl: Command not found`

then you need to contact your system administrator to get perl installed.

Assuming you have perl installed, then type:

`/usr/bin/perl -v`

If you see the same message as before, then you have a proper link to your installed version of perl. However, if you see something like:

`/usr/bin/perl: Command not found`

or you see mention of a lower version of perl, then you need to contact your system administrator and have a link called /usr/bin/perl created that points to your installed version of perl. For example, if you type:

`which perl` (or `type perl` if you're running bash, ksh, or sh)

and you see:

`/usr/sbin/perl`

then the command to create the link would be:

`ln -s /usr/sbin/perl /usr/bin/perl`

but you'll probably need to be logged in as root to be able to execute this command successfully.

### <a name="environment"></a>Setting up the MS2GT Environment

Edit your .cshrc or your .login file and insert the following two lines:

```
setenv MS2GT_HOME $HOME/ms2gt
source $MS2GT_HOME/ms2gt_env.csh
```

If you installed ms2gt into some directory other than $HOME, then change the first line accordingly. If your .cshrc or your .login includes lines such as:

`setenv IDL_DIR /usr/local/rsi/idl`  
`source $IDL_DIR/bin/idl_setup`  
`setenv IDL_PATH ...`

or a line such as

`setenv PATHMPP ...`

then the two MS2GT lines above should be placed after these IDL and PATHMPP lines in the appropriate file. Once your .cshrc or your .login file has been editted, then logout and login again, or else type the following two lines:

`source ~/.cshrc` or  
`source ~/.login`  
`rehash`

Finally, create a writeable directory in your home directory called tmp that will be used by a perl script called idl_sh.pl. This directory will be used for holding temporary shell scripts for running IDL programs:

`mkdir ~/tmp`

### <a name="verifying"></a>Verifying the MS2GT Installation

Try typing in the following three commands to get the syntax of each of the three perl scripts (note that the name of the first script contains a zero (0), followed by a two (2); note that the name of the second script contains a one (1), followed by a zero (0), followed by an underbar (\_), followed by a lower case L (l), followed by a two (2):

`mod02.pl`  
`mod10_l2.pl`  
`mod29.pl`

You should see a usage message that describes the syntax of each perl script that is essentially the same as [mod02_usage](mod02_usage), [mod10_l2_usage](mod10_l2_usage) and [mod29_usage](mod29_usage), respectively. If you get "command not found" or something to that effect, it probably means that your $path is being set after the `source $MS2GT_HOME/ms2gt_env.csh` command in your .cshrc or .login file. Find the line in your .cshrc or .login that looks like:

`set path = <something>`

and change it to:

`set path = ($path <something>)`

Then logout and login and try the commands again.

Next, verify that the environment variable $IDL_PATH is set correctly. Type:

`echo $IDL_PATH`

You should see a directory that looks like:

`something>/ms2gt/src/idl`

as one of the directories in the IDL path. If not, then make sure that you placed the `source $MS2GT_HOME/ms2gt_env.csh` command _after_ setting $IDL_PATH in your .login or .cshrc as decribed [above](#environment).

Finally, verify that the environment varialble $PATHMPP is set correctly. Type:

`echo $PATHMPP`

You should see a directory that looks like:

`<something>/ms2gt/grids`

as one of the directories in PATHMPP. If not, then make sure that you placed the `source $MS2GT_HOME/ms2gt_env.csh` command _after_ setting $PATHMPP in your .login or .cshrc as decribed [above](#environment).

## <a name="using"></a>Using the MS2GT Software

In most cases, users will need to perform the following steps in order to use the MS2GT software (detailed examples of these steps can be found in the [Tutorials](tutorials.html)):

### <a name="searching"></a>Searching for the Data

The user needs to use the [EDG](http://redhook.gsfc.nasa.gov/~imswww/pub/imswelcome/) or a similar tool to find the swath data to be gridded.

### <a name="ordering"></a>Ordering and Downloading the Data

The user needs to use the [EDG](http://redhook.gsfc.nasa.gov/~imswww/pub/imswelcome/) or a similar tool to order and download the swath data to be gridded.

### <a name="command"></a>Creating a MS2GT Command File

The user needs to use a text editor to create a command file for running the particular MS2GT script: [mod02.pl](#mod02), [mod10_l2.pl](#mod10_l2), or [mod29.pl](#mod29) . This command file contains an invocation of the particular script together with its associated parameters. The parameters to a particular script contain the names of miscellaneous text files (described [below](#miscellaneous)) as well as other parameters used to control the operation of the script including a specification of which data arrays in the input file(s) are to be gridded. Alternatively, the invocation of the script and its parameters may be simply typed in on the command line once the miscellaneous text files have been created.

### <a name="miscellaneous"></a>Creating Miscellaneous Text Files

The user needs to use a text editor to create miscellaneous text files used to control the operation of the particular [mod02.pl](#mod02), [mod10_l2.pl](#mod10_l2), or [mod29.pl](#mod29) script.

Each script requires a listfile which contains a list of the filenames of the HDF-EOS files to be gridded. Each of these HDF-EOS files contains MODIS swath data acquired over a five minute interval. Consecutively acquired files can be gridded together to produce a seamless gridded result.

Each script also requires a Grid Parameters Definition (gpd) file, which in turn requires an associated Map Projection Parameters (mpp) file. These files are used by the mapx library software (developed at NSIDC) to define the grid into which the swath data is to be mapped. The format of these files and an explanation of the mapx library is provided in [Points, Pixels, Grids, and Cells](http://cires.colorado.edu/~knowlesk/ppgc.html).

Other miscellaneous text files used by some of the scripts include a chanfile, an ancilfile, and a latlonfile.

The format and use of each miscellaneous file is described [below](#descriptions) as well as in the [Tutorials](tutorials.html).

### <a name="running"></a>Running the MS2GT Command File

Once all the miscellaneous text files have been created, the MS2GT command file can be invoked to actually perform the gridding, or the invocation of the particular MS2GT script and its associated parameters may be simply typed in on the command line.

The MS2GT script runs several IDL and C programs to actually perform the gridding as outlined [above](#how). Further explanations are also provided in the [Tutorials](tutorials.html).

### <a name="examining"></a>Examining the Results

Once the particular MS2GT script has completed processing, there will exist a single binary flat file containing the gridded data for each channel specified in the MS2GT command file. The filenames for each flat file contain fields that specify the type of data the file contains as well as the number of rows and columns in the grid. A detailed description of the filenames created by each script is provided in the [Tutorials](tutorials.html). The MS2GT software does not currently provide any facility for visualizing these data, but they can be easily imported into a variety of visualization programs.

### <a name="geolocating"></a>Geolocating the Results

The MS2GT software contains a utility called gridloc which can be used to create binary floating-point flat files containing the latitude and longitude of each cell in the grid. An example of how to use gridloc can be found at the [end of Tutorial 1](tutorial_1.html#geolocating).

## <a name="descriptions"></a>Script Descriptions and Usage

### <a name="mod02"></a>mod02.pl

This script can process [MOD021KM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD021KM.shtml), [MOD02HKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02HKM.shtml), [MOD02QKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02QKM.shtml), or [MOD03](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD03.shtml) swath files to produce flat binary gridded files containing MODIS Level 1B channel data and/or ancillary data. The channel data consist of up to 36 spectral bands described in [MODIS Technical Specifications](http://modis.gsfc.nasa.gov/about/specs.html). See [Supported Data Sets](#datasets) for a table summarizing which channels are available at which resolutions in which files. The table also shows that ancillary data are available in [MOD021KM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD021KM.shtml) and [MOD03](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD03.shtml) files at 5 km and 1 km resolutions, respectively. Finally the table shows geolocation (lat-lon) data are available at either 1 km or 5 km resolutions. Use of 1 km ancillary data and/or 1 km geolocation data will minimize interpolation error.

The mod02.pl script has the following usage:

```
mod02.pl dirinout tag listfile gpdfile chanfile
                [ancilfile [latlon_src [ancil_src [keep [rind]]]]]
       defaults:   none          1          1       0     50
```

[mod02.pl usage](mod02_usage) provides a cursory explanation of the mod02.pl script parameters. A more expanded discussion of each parameter is provided here. Note that the first five parameters to mod02.pl are required; the rest are optional.

1.  _dirinout_ - the directory containing all input files required by mod02.pl and all output files created by mod02.pl. If input files must reside in some directory other that the one used for output, then the user will need to create links to each of these files in the dirinout directory.
2.  _tag_ - a string used in constructing the names of output files. Each output filename will begin with the _tag_ string.
3.  _listfile_ - the name of a text file containing the names of the [MOD021KM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD021KM.shtml), [MOD02HKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02HKM.shtml), [MOD02QKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02QKM.shtml), or [MOD03](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD03.shtml) swath files to be gridded. If multiple files are present in _listfile_, then the files must all be of the same type (e.g. if the first file is a [MOD021KM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD021KM.shtml) file, then all subsequent files must also be [MOD021KM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD021KM.shtml) files). Multiple files must have been acquired at subsequent acquisition times without any gaps. If _chanfile_ (below) is "none", then _listfile_ must contain a list of one or more [MOD03](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD03.shtml) files from which the 1 km ancillary data specified in ancilfile (below) will be read. If _chanfile_ is not "none", then _listfile_ must contain a list of one or more [MOD021KM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD021KM.shtml), [MOD02HKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02HKM.shtml), or [MOD02QKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02QKM.shtml) files from which the 1 km, 500 m, or 250 m channel data, respectively, specified in _chanfile_ will be read. If, in this latter case, _ancilfile_ is also not "none", then the 5 km data specified in _ancilfile_ will be read from [MOD03](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD03.shtml) files whose filenames are constructed from the corresponding filenames in _chanfile_ by substituting the MOD021KM, MOD02HKM, or MOD02QKM filename prefix with MOD03.
4.  _gpdfile_ - the name of a Grid Parameters Definition (gpd) file that defines the desired output grid. See [Points, Pixels, Grids, and Cells](http://cires.colorado.edu/~knowlesk/ppgc.html) and the [Tutorials](tutorials.html) for more details.
5.  _chanfile_ - the name of a text file containing a list of the channels to be gridded, one line per channel.  If _chanfile_ is "none" then no channel data will be gridded and _ancilfile_ must not be "none". Note that if the first file in _listfile_ is a [MOD03](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD03.shtml) file, then _chanfile_ must be "none" and both _latlon_src_ and _ancil_src_ (described below) are forced to 3\. The channels specified in _chanfile_ are always read from the files specified in _listfile_. Each line in _chanfile_ can have up to four fields. The first field is mandatory; the rest are optional. The fields are:

*   chan - specifies a channel number (1-36).
*   conversion - a string that specifies the type of conversion that should be performed on the channel. The conversion string must be one of the following five values:

*   raw - create a "raw" output file containing raw HDF values (16-bit unsigned integers) (default).
*   corrected - create a "cor" output file containing corrected counts (floating-point).
*   radiance - create a "rad" output file containing radiance values in watts per square meter per steradian per micrometer (floating-point).
*   reflectance - (channels 1-19 and 26) create a "ref" output file containing reflectance values without solar zenith angle correction (floating-point).
*   temperature - (channels 20-25 and 27-36) create a "tem" output file containing brightness temperature values in kelvin (floating-point).

*   weight_type - a string that specifies the type of weighting that should be performed on the channel data during swath-to-grid mapping. The weight_type string must be one of the following two values:

*   avg - use weighted averaging (default). This method can introduce intermediate output values that do not necessarily appear in the input. However it produces an anti-aliased output image.
*   max - use maximum weighting. This method is analogous to nearest neighbor sampling in that it will not result in output values to do not appear in the input. However it can produce aliasing artifacts in the output image.

*   fill - specifies the output fill value to which the input fill value and any unfilled output pixels will be mapped. Default is 0.

8.  _ancilfile_ - the name of a text file containing a list of ancillary parameters to be gridded, one line per parameter. The default is "none" indicating that no ancillary parameters should be gridded. Each line in ancilfile can have up to four fields. The first field is mandatory; the rest are optional. The fields are:

*   param - a string that specifies an ancillary parameter to be gridded. The param string must be one of the following four-character strings:

*   hght - Height - create a "hght" output file containing topographic height values in meters.
*   seze - SensorZenith - create a "seze" output file containing sensor zenith values. Scaled values are in degrees. The scale factor is 0.01.
*   seaz - SensorAzimuth - create a "seaz" output file containing sensor azimuth values.  Scaled values are in degrees. The scale factor is 0.01.
*   rang - Range - create a "rang" output file containing range values. Scaled values are in meters. The scale factor is 25.
*   soze - SolarZenith - create a "soze" output file containing solar zenith values.  Scaled values are in degrees. The scale factor is 0.01.
*   soaz - SolarAzimuth - create a "soaz" output file containing solar azimuth values.  Scaled values are in degrees. The scale factor is 0.01.
*   lmsk - Land/SeaMask -  create a "lmsk" output file containing land/sea mask coded values. This ancillary parameter is available in [MOD03](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD03.shtml) files only. See [MODIS Geolocation Version 2 Product Format](http://daac.gsfc.nasa.gov/DAAC_DOCS/direct_broadcast/MOD03.geolocation.fs.txt) for a description of lmsk coded values.
*   gflg - gflags - create a "gflg" output file containing gflags coded values. See [MODIS Geolocation Version 2 Product Format](http://daac.gsfc.nasa.gov/DAAC_DOCS/direct_broadcast/MOD03.geolocation.fs.txt) for a description of gflags coded values.

*   conversion - a string that specifies the type of conversion that should be performed on the channel. The conversion string must be one of the following:

*   raw - create a "raw" output file containing raw HDF values (16-bit signed integers except that Range is 16-bit unsigned integer and Land/SeaMask and gflags are unsigned bytes) (default).
*   scaled - create a "sca" output file containing raw values multiplied by a parameter-specific scale factor (floating-point). Note that the effective scale factor for Height, Land/SeaMask, and gflags is 1.

*   weight_type - a string that specifies the type of weighting that should be performed on the ancillary parameter data during swath-to-grid mapping. The weight_type string must be one of the following two values:

*   avg - use weighted averaging (default for all except Land/SeaMask and gflags). This method can introduce intermediate output values that do not necessarily appear in the input. However it produces an anti-aliased output image.
*   max - use maximum weighting (default for Land/SeaMask and gflags). This method is analogous to nearest neighbor sampling in that it will not result in output values to do not appear in the input. However it can produce aliasing artifacts in the output image.

*   fill - specifies the output fill value to which the input fill value and any unfilled output pixels will be mapped. Default is 0.

11.  _latlon_src_ - a single character code specifying from where the latitude and longitude data should be read. The codes are as follows:

*   1: use 5 km lat-lon data from [MOD021KM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD021KM.shtml) file (default).
*   3: use 1 km lat-lon data from [MOD03](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD03.shtml) file.
*   H: use 1 km lat-lon data from [MOD02HKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02HKM.shtml) file.
*   Q: use 1 km lat-lon data from [MOD02QKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02QKM.shtml) file.

_latlon_src_

_ancil_src_

_listfile_

[MOD02HKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02HKM.shtml)

[MOD02QKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02QKM.shtml)

[MOD03](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD03.shtml)

19.  _ancil_src_ - a single character code specifying from where the ancillary data should be read. The codes are as follows:

*   1: use 5 km ancillary data from [MOD021KM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD021KM.shtml) file (default).
*   3: use 1 km ancillary data from [MOD03](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD03.shtml) file.

_ancil_src_

_latlon_src_

_listfile_

[MOD03](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD03.shtml)

_ancil_src_

26.  _keep_ - a single character code indicating whether intermediate files should or should not be deleted. The codes are as follows:

*   0: delete intermediate chan, ancil, lat, lon, col, and row files (default).
*   1: do not delete intermediate chan, ancil, lat, lon, col, and row files.

28.  _rind_ - number of pixels to add around intermediate grid to eliminate holes in final grid. Default is 50 which should be adequate in most cases. If you see pixels being set to the fill value along the seam joining adjacent scenes, then you might try increasing the value of _rind_.

### <a name="mod10_l2"></a>mod10_l2.pl

This script can process [MOD10_L2](/data/mod10_l2.html) swath files to produce flat binary gridded files containing MODIS snow cover data. The snow cover data consist of two 500 m resolution "channels" described in [mod10_l2 usage](mod10_l2_usage) and [MOD10_L2](/data/mod10_l2.html). The geolocation information stored in [MOD10_L2](/data/mod10_l2.html) files is 5 km resolution, but 1 km resolution geolocation information extracted from [MOD02HKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02HKM.shtml), [MOD02QKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02QKM.shtml), or [MOD03](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD03.shtml) files if available can be used by mod10_l2.pl via the _latlonlistfile_ parameter (described below). Use of 1 km geolocation information will minimize geolocation interpolation error.

The mod10_l2.pl script has the following usage:

```
mod10_l2.pl dirinout tag listfile gpdfile
                  [chanlist [latlonlistfile [keep [rind]]]]
       defaults:      1          none         0     50
```

[mod10_l2 usage](mod10_l2_usage) provides a cursory explanation of the mod10_l2.pl script parameters. A more expanded discussion of each parameter is provided here. Note that the first four parameters to mod10_l2.pl are required; the rest are optional.

1.  _dirinout_ - the directory containing all input files required by mod10_l2.pl and all output files created by mod10_l2.pl. If input files must reside in some directory other that the one used for output, then the user will need to create links to each of these files in the dirinout directory.
2.  _tag_ - a string used in constructing the names of output files. Each output filename will begin with the _tag_ string.
3.  _listfile_ - the name of a text file containing the names of the [MOD10_L2](/data/mod10_l2.html) swath files to be gridded. Multiple files must have been acquired at subsequent acquisition times without any gaps.
4.  _gpdfile_ - the name of a Grid Parameters Definition (gpd) file that defines the desired output grid. See [Points, Pixels, Grids, and Cells](http://cires.colorado.edu/~knowlesk/ppgc.html) and the [Tutorials](tutorials.html) for more details.
5.  _chanlist_ - string specifying channel numbers to be gridded. The default string is 1, i.e. grid channel 1 only. The channel numbers are:

*   1: Snow Cover - create a "snow" output file containing 8-bit unsigned coded values. See [MODIS/Terra Snow Cover L2 and L3 Daily and 8-Day 500 m](/data/docs/daac/mod10_modis_snow.gd.html) for a table of coded values.
*   2: Snow Cover PixelQA - create a "snqa" output file containing 8-bit unsigned coded values. See [MODIS Snow Cover Bit Processing](/data/docs/daac/mod10_modis_snow/snowcover_qa.html) for a description of coded values.

_chanlist_

_chanlist_

9.  _latlonlistfile_ - text file containing a list of [MOD02HKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02HKM.shtml), [MOD02QKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02QKM.shtml), or [MOD03](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD03.shtml) files whose latitude and longitude data should be used in place of the latitude and longitude data in the corresponding [MOD10_L2](/data/mod10_l2.html) files in listfile. The default is "none" indicating that the latitude and longitude data in each [MOD10_L2](/data/mod10_l2.html) file should be used without substitution.
10.  _keep_ - a single character code indicating whether intermediate files should or should not be deleted. The codes are as follows:

*   0: delete intermediate chan, lat, lon, col, and row files (default).
*   1: do not delete intermediate chan, lat, lon, col, and row files.

12.  _rind_ - number of pixels to add around intermediate grid to eliminate holes in final grid. Default is 50 which should be adequate in most cases. If you see pixels being set to the fill value along the seam joining adjacent scenes, then you might try increasing the value of _rind_.

### <a name="mod29"></a>mod29.pl

This script can process [MOD29](/data/mod29.html) swath files to produce flat binary gridded files containing MODIS sea ice extent data. The sea ice extent data consist of six 1 km resolution "channels" described in [mod29 usage](mod29_usage) and [MOD29](/data/mod29.html). The geolocation information stored in [MOD29](/data/mod29.html) files is 5 km resolution, but 1 km resolution geolocation information extracted from [MOD02HKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02HKM.shtml), [MOD02QKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02QKM.shtml), or [MOD03](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD03.shtml) files if available can be used by mod29.pl via the _latlonlistfile_ parameter (described below). Use of 1 km geolocation information will minimize geolocation interpolation error.

The mod29.pl script has the following usage:

```
mod29.pl dirinout tag listfile gpdfile
                [chanlist [latlonlistfile [keep [rind]]]]
       defaults:    1          none         0     50
```

[mod29 usage](mod29_usage) provides a cursory explanation of the mod29.pl script parameters. A more expanded discussion of each parameter is provided here. Note that the first four parameters to mod29.pl are required; the rest are optional.

1.  _dirinout_ - the directory containing all input files required by mod29.pl and all output files created by mod29.pl. If input files must reside in some directory other that the one used for output, then the user will need to create links to each of these files in the dirinout directory.
2.  _tag_ - a string used in constructing the names of output files. Each output filename will begin with the _tag_ string.
3.  _listfile_ - the name of a text file containing the names of the [MOD29](/data/mod29.html) swath files to be gridded. Multiple files must have been acquired at subsequent acquisition times without any gaps.
4.  _gpdfile_ - the name of a Grid Parameters Definition (gpd) file that defines the desired output grid. See [Points, Pixels, Grids, and Cells](http://cires.colorado.edu/~knowlesk/ppgc.html) and the [Tutorials](tutorials.html) for more details.
5.  _chanlist_ - string specifying channel numbers to be gridded. The default string is 1, i.e. grid channel 1 only. The channel numbers are:

*   1: Sea Ice by Reflectance - create an "icer" output file containing 8-bit unsigned coded values. See [MODIS/Terra Sea Ice Extent L2 and L3 Day and Night 1 km](/data/docs/daac/mod29_modis_seaice.gd.html) for a table of coded values.
*   2: Sea Ice by Reflectance PixelQA - create a "irqa" output file containing 8-bit unsigned coded values. See [MODIS Sea Ice Bit Processing](/data/docs/daac/mod29_modis_seaice/seaice_qa.html) for a description of values.
*   3: Ice Surface Temperature - create a "temp" output file containing 16-bit unsigned values representing kelvin * 100\. Note that the 16-bit unsigned values should be divided by 100\. Resulting values in the range 0-255 represent coded values while 655.35 represents the fill value; all other values represent temperatures in kelvin. See [MODIS/Terra Sea Ice Extent L2 and L3 Day and Night 1 km](/data/docs/daac/mod29_modis_seaice.gd.html) for a table of coded values.
*   4: Ice Surface Temperature PixelQA - create a "itqa" output file containing 8-bit unsigned coded values. See [MODIS Sea Ice Bit Processing](/data/docs/daac/mod29_modis_seaice/seaice_qa.html) for a description of values.
*   5: Sea Ice by IST - create a "icet" output file containing 8-bit unsigned coded values. See [MODIS/Terra Sea Ice Extent L2 and L3 Day and Night 1 km](/data/docs/daac/mod29_modis_seaice.gd.html) for a table of coded values.
*   6: icrt Combined Sea Ice - create a "icrt" output file containing 8-bit unsigned coded values. See [MOD29 Local Attributes](/data/docs/daac/mod29_modis_seaice/mod29_local_attributes.html) for a table of coded values.

_chanlist_

_chanlist_



[MOD29](/data/mod29.html)

[MOD29](/data/mod29.html)

12.  _latlonlistfile_ - text file containing a list of [MOD02HKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02HKM.shtml), [MOD02QKM](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD02QKM.shtml), or [MOD03](http://daac.gsfc.nasa.gov/MODIS/Terra/rad_geo/MOD03.shtml) files whose latitude and longitude data should be used in place of the latitude and longitude data in the corresponding [MOD29](/data/mod29.html) files in listfile. The default is "none" indicating that the latitude and longitude data in each [MOD29](/data/mod29.html) file should be used without substitution.
13.  _keep_ - a single character code indicating whether intermediate files should or should not be deleted. The codes are as follows:

*   0: delete intermediate chan, lat, lon, col, and row files (default).
*   1: do not delete intermediate chan, lat, lon, col, and row files.

15.  _rind_ - number of pixels to add around intermediate grid to eliminate holes in final grid. Default is 50 which should be adequate in most cases. If you see pixels being set to the fill value along the seam joining adjacent scenes, then you might try increasing the value of _rind_.

* * *

<font size="-1">Last updated: January 2, 2002 by</font>  
<font size="-1">Terry Haran</font>  
<font size="-1">NSIDC-CIRES</font>  
<font size="-1">449 UCB</font>  
<font size="-1">University of Colorado</font>  
<font size="-1">Boulder, CO 80309-0449</font>  
<font size="-1">303-492-1847</font>  
<font size="-1">[tharan@nsidc.org](mailto:tharan@nsidc.org)</font>
