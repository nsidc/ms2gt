MS2GT
-----

### The MODIS Swath-to-Grid Toolbox

*Documentation for this product is in development.\
For more information, [contact NSIDC User Services](https://nsidc.org/about/contact.html).*

### Table of Contents

-   [Overview](https://nsidc.org/data/modis/ms2gt#overview)
    -   [What the Software Does](https://nsidc.org/data/modis/ms2gt#what)
    -   [How the Software Works](https://nsidc.org/data/modis/ms2gt#how)
    -   [Requirements](https://nsidc.org/data/modis/ms2gt#requirements)
    -   [Supported Data Sets](https://nsidc.org/data/modis/ms2gt#datasets)
-   [Installation Instructions](https://nsidc.org/data/modis/ms2gt#installation)
    -   [Obtaining the Software](https://nsidc.org/data/modis/ms2gt#obtaining)
    -   [Building the Executables](https://nsidc.org/data/modis/ms2gt#building)
    -   [Verifying your Perl Installation](https://nsidc.org/data/modis/ms2gt#perl)
    -   [Setting up the MS2GT Environment](https://nsidc.org/data/modis/ms2gt#environment)
    -   [Verifying the MS2GT Installation](https://nsidc.org/data/modis/ms2gt#verifying)
-   [Using the MS2GT Software](https://nsidc.org/data/modis/ms2gt#using)
    -   [Obtaining the Data](https://nsidc.org/data/modis/ms2gt#searching)
    -   [Creating a MS2GT Command File](https://nsidc.org/data/modis/ms2gt#command)
    -   [Creating Miscellaneous Text Files](https://nsidc.org/data/modis/ms2gt#miscellaneous)
    -   [Running the MS2GT Command File](https://nsidc.org/data/modis/ms2gt#running)
    -   [Examining the Results](https://nsidc.org/data/modis/ms2gt#examining)
    -   [Geolocating the Results](https://nsidc.org/data/modis/ms2gt#geolocating)
-   [Script Descriptions and Usage](https://nsidc.org/data/modis/ms2gt#descriptions)
    -   [mod02.pl - MODIS Level 1B Channel or Ancillary Data](https://nsidc.org/data/modis/ms2gt#mod02)
    -   [mod10_l2.pl - Snow Cover Data](https://nsidc.org/data/modis/ms2gt#mod10_l2)
    -   [mod29.pl - Sea Ice Extent Data](https://nsidc.org/data/modis/ms2gt#mod29)
-   [Version History](https://nsidc.org/data/modis/ms2gt#history)
-   [Tutorials](https://nsidc.org/data/modis/ms2gt/tutorials.html)

### Overview

#### What the Software Does

The MODIS Swath-to-Grid Toolbox (MS2GT) is a set of software tools that reads HDF-EOS files containing MODIS swath data and produces flat binary files containing gridded data in a variety of map projections. MS2GT can produce a seamless output grid from multiple input files corresponding to successively acquired, 5-minute MODIS scenes. MS2GT consists of three perl programs that make calls to several standalone IDL and C programs: [mod02.pl](https://nsidc.org/data/modis/ms2gt#mod02) which reads [MOD021KM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf), [MOD02HKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf), or [MOD02QKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf) Level 1b files, [mod10_l2.pl](https://nsidc.org/data/modis/ms2gt#mod10_l2) which reads [MOD10_L2](https://nsidc.org/data/mod10_l2.html) snow cover files, and [mod29.pl](https://nsidc.org/data/modis/ms2gt#mod29) which reads [MOD29](https://nsidc.org/data/mod29v5.html) sea ice files.  All three Perl programs can optionally read [MOD03](https://modis.gsfc.nasa.gov/data/dataprod/dataproducts.php?MOD_NUMBER=03) files for geolocation information. In addition, [mod02.pl](https://nsidc.org/data/modis/ms2gt#mod02) can extract ancillary data (such as illumination and viewing angles) from [MOD03](https://modis.gsfc.nasa.gov/data/dataprod/dataproducts.php?MOD_NUMBER=03) files.

#### How the Software Works

Each of the three Perl scripts provided with MS2GT make similar calls to the IDL and C programs outlined below:

-   IDL programs written by Liam Gumley of [SSEC at the University of Wisconsin](http://www.ssec.wisc.edu/) read user-specified data arrays out of HDF-EOS files. During this step, radiance data can remain as raw integer counts or be converted to floating-point corrected counts, radiances, or reflectances. Thermal data can remain as raw counts or be converted to temperatures. These swath data arrays, including latitude and longitude arrays, are saved as temporary data files.
-   The latitude and longitude files are then converted to files containing column and row numbers of the target grid by a C program called ll2cr, which uses the mapx C library written by Ken Knowles of NSIDC. The mapx library requires a user-supplied [Grid Parameters Definition](https://support.nsidc.org/hc/en-us/articles/227753147) (gpd) text file that specifies the desired grid and associated map projection.
-   The column and row files and any ancillary data files are then interpolated to the resolution of the primary data files (1 km for [MOD021KM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf) and [MOD29](https://nsidc.org/data/mod29v5.html), 500 m for [MOD02HKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf) and [MOD10_L2](https://nsidc.org/data/mod10_l2.html), or 250 m for [MOD02QKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf)) as necessary using two IDL programs (interp_colrow.pro and interp_swath.pro).
-   In the final step, a C program called fornav performs forward navigation on the interpolated column and row files, with the primary data files and any interpolated ancillary data files to produce gridded, flat binary files. You can specify that either elliptical weighted averaging or elliptical maximum weight sampling be used during forward navigation.

It should be relatively easy for users familiar with Perl and IDL programming to modify the Perl scripts and IDL procedures to process other kinds of swath data using many of the same standalone programs provided with MS2GT. Find further details in the [Tutorials](https://nsidc.org/data/modis/ms2gt/tutorials.html).

#### Requirements

In its current form, MS2GT runs on a Unix workstation with a standard C compiler. It also requires Perl 5.0 or higher and IDL 5.0 or higher. The installation instructions assume csh or tcsh as the Unix shell. Users of other shells (e.g. bash, ksh, sh, etc.) may need to make slight changes to the installation instructions.

MS2GT was developed and tested on an SGI O2 workstation having 192 Mb of memory and running IRIX 6.5, perl 5.004_04, and IDL 5.4. Developers minimized memory requirements at the expense of increased temporary disk storage requirements and slightly slower speed. However, in its current form, MS2GT requires that two times a grid's worth of single precision floating-point data for one channel fit into virtual memory. The result is that fairly large gridded images can be created on a machine with a modest amount of memory in a fairly short time. For example, the creation of two 1316 x 1384 250 m grids containing MODIS channels 1 and 2 reflectance data derived from a single [MOD02QKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf) file takes about three minutes on the above machine and requires about 2 * 1316 * 1384 * 4 = 15 MB of free virtual memory.

#### Supported Data Sets

See the [MODIS Home Page](https://modis.gsfc.nasa.gov/) for general information on the MODIS instrument. See [MODIS Snow and Ice Products](https://nsidc.org/data/modis/data_summaries) for information on MODIS snow and ice products distributed by NSIDC.

| Short Name | Long Name | Channel Data | Ancillary | Lat-lon |
| [MOD021KM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf) | MODIS/TERRA CALIBRATED RADIANCES 5-MIN L1B SWATH 1KM | 1-36 @ 1 km | 7 @ 5 km | 5 km |
| [MOD02HKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf) | MODIS/TERRA CALIBRATED RADIANCES 5-MIN L1B SWATH 500M | 1-7 @ 500 m | none | 1 km |
| [MOD02QKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf) | MODIS/TERRA CALIBRATED RADIANCES 5-MIN L1B SWATH 250M | 1-2 @ 250 m | none | 1 km |
| [MOD03](https://modis.gsfc.nasa.gov/data/dataprod/dataproducts.php?MOD_NUMBER=03) | MODIS/TERRA GEOLOCATION FIELDS 5-MIN L1A SWATH 1KM | none | 8 @ 1 km | 1 km |
| [MOD10_L2](https://nsidc.org/data/mod10_l2.html) | MODIS/TERRA SNOW COVER 5-MIN L2 SWATH 500M | 2 @ 500 m | none | 5 km |
| [MOD29](https://nsidc.org/data/mod29v5.html) | MODIS/TERRA SEA ICE EXTENT 5-MIN L2 SWATH 1KM | 6 @ 1 km | none | 5 km |

### Installation Instructions

#### Obtaining the Software

The software and associated documentation can be downloaded from <ftp://sidads.colorado.edu/pub/NSIDC/ms2gt0.5.tar.gz>. Save this file into an appropriate directory. If you have a previous version of MS2GT installed in the same directory, either remove the older version or rename it. For example:

**`rm -fr ms2gt`**

or change the name:

**`mv ms2gt ms2gt.old`**

To uncompress the ms2gt file, from the command line, type:

**`gunzip -dc ms2gt0.5.tar.gz | tar xvf -`**

This creates a directory in the current directory called ms2gt, which will contain several subdirectories. Find further instructions on installing and using MS2GT in html files in the ms2gt/doc subdirectory. After you have uncompressed the tar.gz file, you may delete it.

In your browser, navigate to this document in your ms2gt directory (ms2gt/doc/index.html).

#### Building the Executables

From the command line, navigate to the current working directory (ms2gt/src)

**`make all`**

This builds and installs the MS2GT executables under the ms2gt directory. The only write privileges required are the ability to write into the ms2gt directory and its subdirectories.

#### Verifying your Perl 5.0 Installation

From the command line, type:

**`perl -v`**

When perl version 5 or greater is installed, you will see a message such as the following:

`This is perl, version 5.004_04 built for irix-n32`

`Copyright 1987-1997, Larry Wall`

`Perl may be copied only under the terms of either the Artistic License or the`\
`GNU General Public License, which may be found in the Perl 5.0 source kit.`

However, if you see the following:

`perl: Command not found`

then contact your system administrator to have perl installed.

When you have perl installed, type:

**`/usr/bin/perl -v`**

If you see the same message as before, then you have a proper link to your installed version of perl.

However, if you see something like:

`/usr/bin/perl: Command not found`

or you have a previous version of perl, then contact your system administrator to create a link called /usr/bin/perl. The link points to your installed version of perl. For example, if you type:

**`which perl `**(or **`type perl` **if you're running bash, ksh, or sh)

and you see:

`/usr/sbin/perl`

then the command to create the link would be:

**`ln -s /usr/sbin/perl /usr/bin/perl`**

#### Setting up the MS2GT Environment

Edit your .cshrc or your .login file and look for IDL lines such as the following:

`setenv IDL_DIR /usr/local/rsi/idl`\
`source $IDL_DIR/bin/idl_setup`\
`setenv IDL_PATH ...`

`or a line such as`

`setenv PATHMPP ...`

If the file contains any of those lines, insert the following two lines after the IDL and PATHMPP lines. If the file does not contain those lines, insert the following lines anywhere in the file:

`setenv MS2GT_HOME $HOME/ms2gt`\
`source $MS2GT_HOME/ms2gt_env.csh`

If you installed ms2gt into some directory other than $HOME, then change the first line accordingly.

Once your .cshrc or your .login file has been edited, log out and log in again, or type the following two lines:

**`source ~/.cshrc `**or\
**`source ~/.login`**\
**`rehash`**

Finally, from your home directory, create a writeable tmp directory

**`mkdir ~/tmp`**

This directory will be used for holding temporary shell scripts for running IDL programs.

#### Verifying the MS2GT Installation

Verify the ms2gt installation by viewing the syntax messages for each perl script:

**`mod02.pl`**\
**`mod10_l2.pl`**\
**`mod29.pl`**

You should see a usage message that describes the syntax of each perl script: [mod02_usage](https://nsidc.org/data/modis/ms2gt/mod02_usage.txt), [mod10_l2_usage](https://nsidc.org/data/modis/ms2gt/mod10_l2_usage.txt) and [mod29_usage](https://nsidc.org/data/modis/ms2gt/mod29_usage.txt), respectively. If you see "command not found", it may mean that your $path is being set after the `source $MS2GT_HOME/ms2gt_env.csh `command in your .cshrc or .login file.

Find the line in your .cshrc or .login that looks like:

`set path = <*name*>`

and change it to:

`set path = ($path <*name*>)`

Then log out and log in and try the commands again.

Next, verify that the environment variable $IDL_PATH is set correctly.

From the command line, type:

**`echo $IDL_PATH`**

You should see a directory that looks like the following:

<`*name*>/ms2gt/src/idl`

as one of the directories in the IDL path. If you do not, then make sure that you placed the `source` `$MS2GT_HOME/ms2gt_env.csh `command *after* setting $IDL_PATH in your .login or .cshrc as described [above](https://nsidc.org/data/modis/ms2gt#environment).

Finally, verify that the environment variable $PATHMPP is set correctly.

Type:

**`echo $PATHMPP`**

You should see a directory that looks like:

<name>/ms2gt/grids

as one of the directories in PATHMPP. If you do not, then make sure that you placed the `source $MS2GT_HOME/ms2gt_env.csh `command *after *setting $PATHMPP in your .login or .cshrc as described [above](https://nsidc.org/data/modis/ms2gt#environment).

### Using the MS2GT Software

In most cases, you need to perform the following steps to use the MS2GT software (detailed examples of these steps are in the [Tutorials](https://nsidc.org/data/modis/ms2gt/tutorials.html)).

#### Obtaining the Data

Visit the [MODIS Data | Order Data](https://nsidc.org/data/modis/order_data.html) page to find and order or download the swath data to be gridded.

#### Creating an MS2GT Command File

Use a text editor to create a command file for running the particular MS2GT script: [mod02.pl](https://nsidc.org/data/modis/ms2gt#mod02), [mod10_l2.pl](https://nsidc.org/data/modis/ms2gt#mod10_l2), or [mod29.pl](https://nsidc.org/data/modis/ms2gt#mod29) . This command file contains an invocation of the particular script with its associated parameters. The parameters to a particular script contain the names of miscellaneous text files (described [below](https://nsidc.org/data/modis/ms2gt#miscellaneous)), as well as other parameters used to control the operation of the script. Parameters include a specification of which data arrays in the input file(s) are to be gridded. Alternatively, you can type the script name on the command line once the miscellaneous text files have been created.

#### Miscellaneous Text Files

The [Tutorials](https://nsidc.org/data/modis/ms2gt/tutorials.html) give specific examples of how to create the text files that control the scripts. This section outline the requirements for the text files.

Each script requires a listfile that contains a list of the filenames of the HDF-EOS files to be gridded. Each of these HDF-EOS files contains MODIS swath data acquired over a five-minute interval. Consecutively acquired files can be gridded together to produce a seamless gridded result.

Each script also requires a Grid Parameters Definition (gpd) file, which in turn requires an associated Map Projection Parameters (mpp) file. These files are used by the mapx library software (developed at NSIDC) to define the grid into which the swath data is to be mapped. The format of these files and an explanation of the mapx library is provided in the [Points, Pixels, Grids, and Cells: A Mapping and Gridding Primer](https://nsidc.org/support/how/Points-Pixels-Grids-and-Cells-A-Mapping-and-Gridding-Primer) document.

Other miscellaneous text files used by some of the scripts include a chanfile, an ancilfile, and a latlonfile.

The format and use of each miscellaneous file is described [below](https://nsidc.org/data/modis/ms2gt#descriptions) as well as in the [Tutorials](https://nsidc.org/data/modis/ms2gt/tutorials.html).

#### Running the MS2GT Command File

Once all the miscellaneous text files have been created, you can invoke the MS2GT command file to actually perform the gridding. You can also invoke the particular MS2GT script and its associated parameters by typing on the command line. The MS2GT script runs several IDL and C programs to perform the gridding as outlined [above](https://nsidc.org/data/modis/ms2gt#how). Further explanations are also provided in the [Tutorials](https://nsidc.org/data/modis/ms2gt/tutorials.html).

#### Examining the Results

Once an MS2GT script has completed processing, there will be a single, binary flat file containing the gridded data for each channel specified in the MS2GT command file. The filenames for each flat file contain fields that specify the type of data the file contains as well as the number of rows and columns in the grid. A detailed description of the filenames created by each script is provided in the [Tutorials](https://nsidc.org/data/modis/ms2gt/tutorials.html). The MS2GT software does not currently provide any facility for visualizing these data, but they can be easily imported into a variety of visualization programs.

#### Geolocating the Results

The MS2GT software contains a utility called gridloc, which can be used to create binary floating-point flat files containing the latitude and longitude of each cell in the grid. See an example of how to use gridloc at the [end of Tutorial 1](https://nsidc.org/data/modis/ms2gt/tutorial_1.html#geolocating).

### Script Descriptions and Usage

#### mod02.pl - MODIS Level-1B Channel or Ancillary Data

This script can process [MOD021KM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf), [MOD02HKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf), [MOD02QKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf), or [MOD03](https://modis.gsfc.nasa.gov/data/dataprod/dataproducts.php?MOD_NUMBER=03) swath files to produce flat binary gridded files containing MODIS Level-1B channel data and/or ancillary data. The channel data consist of up to 36 spectral bands, as described in the [MODIS Technical Specifications](https://modis.gsfc.nasa.gov/about/specifications.php). See [Supported Data Sets](https://nsidc.org/data/modis/ms2gt#datasets) for a table summarizing which channels are available at which resolutions in which files. The table also shows that ancillary data are available in [MOD021KM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf) and [MOD03](https://modis.gsfc.nasa.gov/data/dataprod/dataproducts.php?MOD_NUMBER=03) files at 5 km and 1 km resolutions, respectively. Finally the table shows geolocation (lat-lon) data are available at either 1 km or 5 km resolutions. Using 1 km ancillary data and/or 1 km geolocation data will minimize interpolation error.

The mod02.pl script has the following usage:

`mod02.pl dirinout tag listfile gpdfile chanfile`\
`                [ancilfile [latlon_src [ancil_src [keep [rind]]]]]`\
`       defaults:   none          1          1       0     50`

The file [mod02_usage](https://nsidc.org/data/modis/ms2gt/mod02_usage.txt) provides a cursory explanation of the mod02.pl script parameters. A more expanded discussion of each parameter is provided below. Note that the first five parameters to mod02.pl are required; the rest are optional.

| Parameter | Description |
| *dirinout* | The directory containing all input files required by mod02.pl and all output files created by mod02.pl. If input files must reside in some directory other than the one used for output, then you must create links to each of these files in the dirinout directory. |
| *tag* | A string used in constructing the names of output files. Each output filename begins with the *tag* string. |
| *listfile* | The name of a text file containing the names of the [MOD021KM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf), [MOD02HKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf), [MOD02QKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf), or [MOD03](https://modis.gsfc.nasa.gov/data/dataprod/dataproducts.php?MOD_NUMBER=03) swath files to be gridded. If multiple files are present in *listfile*, then the files must all be of the same type (e.g. if the first file is a MOD021KM file, then all subsequent files must also be MOD021KM files). Multiple files must have been acquired at subsequent times without any gaps. If *chanfile* (below) is none, then *listfile* must contain a list of one or more MOD03 files from which the 1-km ancillary data specified in ancilfile (below) will be read. If *chanfile* is not none , then *listfile* must contain a list of one or more MOD021KM, MOD02HKM, or MOD02QKM files from which the 1 km, 500 m, or 250 m channel data, specified in *chanfile*, will be read. If, in this latter case, *ancilfile* is also not none, then the 5-km data specified in *ancilfile* will be read from MOD03 files whose filenames are constructed from the corresponding filenames in *chanfile* by substituting the MOD021KM, MOD02HKM, or MOD02QKM filename prefix with MOD03. |
| *gpdfile* | The name of a Grid Parameters Definition (gpd) file that defines the desired output grid. Refer to the [Points, Pixels, Grids, and Cells: A Mapping and Gridding Primer](https://nsidc.org/support/how/Points-Pixels-Grids-and-Cells-A-Mapping-and-Gridding-Primer) document and the [Tutorials](https://nsidc.org/data/modis/ms2gt/tutorials.html) for more details. |
| *chanfile* | The name of a text file containing a list of the channels to be gridded, one line per channel.  If *chanfile* is none, then no channel data will be gridded and *ancilfile* must not be none. Note that if the first file in *listfile* is a [MOD03](https://modis.gsfc.nasa.gov/data/dataprod/dataproducts.php?MOD_NUMBER=03)file, then *chanfile* must be none, and both *latlon_src* and *ancil_src* (described below) are forced to 3. The channels specified in *chanfile* are always read from the files specified in *listfile*. Each line in *chanfile *can have up to four fields. The first field is mandatory; the rest are optional. The fields are:

`chan conversion weight_type fill`

and are defined as follows:

-   chan - specifies a channel number (1-36).
-   conversion - a string that specifies the type of conversion to perform on the channel. The conversion string must be one of the following five values:
    -   raw - create a raw output file containing raw HDF values (16-bit unsigned integers). This is the default.
    -   corrected - create a cor output file containing corrected counts (floating-point).
    -   radiance - create a rad output file containing radiance values in watts per square meter per steradian per micrometer (floating-point).
    -   reflectance - (channels 1-19 and 26) create a ref output file containing reflectance values without solar zenith angle correction (floating-point).
    -   temperature - (channels 20-25 and 27-36) create a tem output file containing brightness temperature values in kelvin (floating-point).
-   weight_type - a string that specifies the type of weighting to perform on the channel data during swath-to-grid mapping. The weight_type string must be one of the following two values:
    -   avg - use weighted averaging. (This is the default). This method can introduce intermediate output values that do not necessarily appear in the input. However, it produces an anti-aliased output image.
    -   max - use maximum weighting. This method is analogous to nearest neighbor sampling in that it will not result in output values to do not appear in the input. However it can produce aliasing artifacts in the output image.
-   fill - specifies the output fill value to which the input fill value and any unfilled output pixels will be mapped. The default is 0.

 |
| *ancilfile* | The name of a text file containing a list of ancillary parameters to be gridded, one line per parameter. The default is none, indicating that no ancillary parameters should be gridded. Each line in ancilfile can have up to four fields. The first field is mandatory; the rest are optional. The fields are:

`param conversion weight_type fill`

and are defined as follows:

-   param - a string that specifies an ancillary parameter to be gridded. The param string must be one of the following four-character strings:
    -   hght - Height - create a hght output file containing topographic height values in meters.
    -   seze - SensorZenith - create a seze output file containing sensor zenith values. Scaled values are in degrees. The scale factor is 0.01.
    -   seaz - SensorAzimuth - create a seaz output file containing sensor azimuth values.  Scaled values are in degrees. The scale factor is 0.01.
    -   rang - Range - create a rang output file containing range values. Scaled values are in meters. The scale factor is 25.
    -   soze - SolarZenith - create a soze output file containing solar zenith values.  Scaled values are in degrees. The scale factor is 0.01.
    -   soaz - SolarAzimuth - create a soaz output file containing solar azimuth values.  Scaled values are in degrees. The scale factor is 0.01.
    -   lmsk - Land/SeaMask -  create an lmsk output file containing land/sea mask coded values. This ancillary parameter is available in [MOD03](https://modis.gsfc.nasa.gov/data/dataprod/dataproducts.php?MOD_NUMBER=03) files only.
    -   gflg - gflags - create a gflg output file containing gflags coded values.
-   conversion - a string that specifies the type of conversion to perform on the channel. The conversion string must be one of the following:
    -   raw - create a raw output file containing raw HDF values (16-bit signed integers except that Range is 16-bit unsigned integer and Land/SeaMask and gflags are unsigned bytes). (This is the default.)
    -   scaled - create a sca output file containing raw values multiplied by a parameter-specific scale factor (floating-point). Note that the effective scale factor for Height, Land/SeaMask, and gflags is 1.
-   weight_type - a string that specifies the type of weighting to perform on the ancillary parameter data during swath-to-grid mapping. The weight_type string must be one of the following two values:
    -   avg - use weighted averaging (default for all except Land/SeaMask and gflags). This method can introduce intermediate output values that do not necessarily appear in the input. However it produces an anti-aliased output image.
    -   max - use maximum weighting (default for Land/SeaMask and gflags). This method is analogous to nearest neighbor sampling in that it will not result in output values to do not appear in the input. However it can produce aliasing artifacts in the output image.
-   fill - specifies the output fill value to which the input fill value and any unfilled output pixels will be mapped. Default is 0.

 |
| *latlon_src* | A single character code specifying from where the latitude and longitude data should be read. The codes are as follows:

-   1: use 5 km lat-lon data from [MOD021KM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf) file (default).
-   3: use 1 km lat-lon data from [MOD03](https://modis.gsfc.nasa.gov/data/dataprod/dataproducts.php?MOD_NUMBER=03) file.
-   H: use 1 km lat-lon data from [MOD02HKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf) file.
-   Q: use 1 km lat-lon data from [MOD02QKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf) file.

Note that if *latlon_src* is set to 3, then *ancil_src* (below) is forced to 3. Note also that if the first file specified in *listfile* is a [MOD02HKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf), [MOD02QKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf), or [MOD03](https://modis.gsfc.nasa.gov/data/dataprod/dataproducts.php?MOD_NUMBER=03) file, then latlon_src is forced to H, Q, or 3, respectively. |
| *ancil_src* | A single character code specifying from where the ancillary data should be read. The codes are as follows:

-   1: use 5-km ancillary data from [MOD021KM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf) file. (This is the default.)
-   3: use 1 km ancillary data from [MOD03](https://modis.gsfc.nasa.gov/data/dataprod/dataproducts.php?MOD_NUMBER=03) file.

Note that if *ancil_src* is set to 3, then *latlon_src* is forced to 3. Also, if the first file specified in *listfile* is a [MOD03](https://modis.gsfc.nasa.gov/data/dataprod/dataproducts.php?MOD_NUMBER=03) file, then *ancil_src* is forced to 3. |
| *keep* | A single character code indicating whether intermediate files should or should not be deleted. The codes are as follows:

-   0: delete intermediate chan, ancil, lat, lon, col, and row files. (This is the default.)
-   1: do not delete intermediate chan, ancil, lat, lon, col, and row files.

 |
| *rind* | The number of pixels to add around intermediate grid to eliminate holes in final grid. The default is 50, which should be adequate in most cases. If you see pixels being set to the fill value along the seam joining adjacent scenes, then try increasing the value of *rind*. |

#### mod10_l2.pl - Snow Cover Data

This script can process [MOD10_L2](https://nsidc.org/data/mod10_l2.html) swath files to produce flat binary gridded files containing MODIS snow cover data. The snow cover data consist of 2 500-m resolution channels described in [mod10_l2 usage](https://nsidc.org/data/modis/ms2gt/mod10_l2_usage.txt) and [MOD10_L2](https://nsidc.org/data/mod10_l2.html).

The geolocation information stored in [MOD10_L2](https://nsidc.org/data/mod10_l2.html) files is 5-km resolution, but 1-km resolution geolocation information extracted from [MOD02HKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf), [MOD02QKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf), or [MOD03](https://modis.gsfc.nasa.gov/data/dataprod/dataproducts.php?MOD_NUMBER=03) files, if available, can be used by mod10_l2.pl via the *latlonlistfile* parameter (described below). Using 1-km geolocation information will minimize geolocation interpolation error.

The mod10_l2.pl script has the following usage:

`mod10_l2.pl dirinout tag listfile gpdfile`\
`                  [chanlist [latlonlistfile [keep [rind]]]]`\
`       defaults:      1          none         0     50`

[mod10_l2 usage](https://nsidc.org/data/modis/ms2gt/mod10_l2_usage.txt) provides a cursory explanation of the mod10_l2.pl script parameters. A more expanded discussion of each parameter is provided here. Note that the first four parameters to mod10_l2.pl are required; the rest are optional.

| Parameter | Description |
| *dirinout* | The directory containing all input files required by mod10_l2.pl and all output files created by mod10_l2.pl. If input files must reside in some directory other than the one used for output, then you must create links to each of these files in the dirinout directory. |
| *tag* | A string used in constructing the names of output files. Each output filename begins with the *tag* string. |
| *listfile* | The name of a text file containing the names of the [MOD10_L2](https://nsidc.org/data/mod10_l2.html) swath files to be gridded. Multiple files must have been acquired at subsequent times without any gaps. |
| *gpdfile* | The name of a Grid Parameters Definition (gpd) file that defines the desired output grid. Refer to the [Points, Pixels, Grids, and Cells: A Mapping and Gridding Primer](https://nsidc.org/support/how/Points-Pixels-Grids-and-Cells-A-Mapping-and-Gridding-Primer) document and the [Tutorials](https://nsidc.org/data/modis/ms2gt/tutorials.html) for more details. |
| *chanlist* | string specifying channel numbers to be gridded. The default string is 1, i.e. grid channel 1 only. The channel numbers are:

-   1: Snow Cover - create a snow output file containing 8-bit unsigned coded values. See the [MODIS/Terra Snow Cover 5-Min L2 Swath 500m](https://nsidc.org/data/docs/daac/modis_v5/mod10_l2_modis_terra_snow_cover_5min_swath.gd.html) documentation for a table of coded values.
-   2: Snow Cover PixelQA - create a "snqa" output file containing 8-bit unsigned coded values. See [MODIS Snow Cover Bit Processing](https://nsidc.org/data/docs/daac/mod10_modis_snow/snowcover_qa.html) for a description of coded values.

The *chanlist* string should not contain any embedded blanks. To specify that all channels should be gridded, specify 12 for *chanlist*. |
| *latlonlistfile* | A text file containing a list of [MOD02HKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf), [MOD02QKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf), or [MOD03](https://modis.gsfc.nasa.gov/data/dataprod/dataproducts.php?MOD_NUMBER=03) files whose latitude and longitude data should be used in place of the latitude and longitude data in the corresponding [MOD10_L2](https://nsidc.org/data/mod10_l2.html) files in listfile. The default is none, indicating that the latitude and longitude data in each [MOD10_L2](https://nsidc.org/data/mod10_l2.html) file should be used. |
| *keep* | A single character code indicating whether intermediate files should or should not be deleted. The codes are as follows:

-   0: delete intermediate chan, lat, lon, col, and row files. (This is the default.)
-   1: do not delete intermediate chan, lat, lon, col, and row files.

 |
| *rind* | The number of pixels to add around the intermediate grid to eliminate holes in final grid. The default is 50, which is adequate in most cases. If you see pixels being set to the fill value along the seam joining adjacent scenes, then try increasing the value of *rind*. |

#### mod29.pl - Sea Ice Extent Data

This script can process [MOD29](https://nsidc.org/data/mod29v5.html) swath files to produce flat binary gridded files containing MODIS sea ice extent data. The sea ice extent data consist of six 1 km resolution channels described in [mod29 usage](https://nsidc.org/data/modis/data/modis/ms2gt/mod29_usage.txt) and [MOD29](https://nsidc.org/data/mod29v5.html). The geolocation information stored in [MOD29](https://nsidc.org/data/mod29v5.html) files is 5 km resolution, but 1 km resolution geolocation information extracted from [MOD02HKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf), [MOD02QKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf), or [MOD03](https://modis.gsfc.nasa.gov/data/dataprod/dataproducts.php?MOD_NUMBER=03) files, if available, can be used by mod29.pl via the *latlonlistfile* parameter (described below). Using 1-km geolocation information will minimize geolocation interpolation error.

The mod29.pl script has the following usage:

`mod29.pl dirinout tag listfile gpdfile`\
`                [chanlist [latlonlistfile [keep [rind]]]]`\
`       defaults:    1          none         0     50`

[mod29_usage](https://nsidc.org/data/modis/ms2gt/mod29_usage.txt) provides a cursory explanation of the mod29.pl script parameters. A more expanded discussion of each parameter is provided here. Note that the first four parameters to mod29.pl are required; the rest are optional.

| *dirinout* | The directory containing all input files required by mod29.pl and all output files created by mod29.pl. If input files must reside in some directory other that the one used for output, then you must create links to each of these files in the dirinout directory. |
| *tag* | A string used in constructing the names of output files. Each output filename will begin with the *tag* string. |
| *listfile* | The name of a text file containing the names of the [MOD29](https://nsidc.org/data/mod29v5.html) swath files to be gridded. Multiple files must have been acquired at subsequent acquisition times without any gaps. |
| *gpdfile* | The name of a Grid Parameters Definition (gpd) file that defines the desired output grid. Refer to the [Points, Pixels, Grids, and Cells: A Mapping and Gridding Primer](https://nsidc.org/support/how/Points-Pixels-Grids-and-Cells-A-Mapping-and-Gridding-Primer) document and the [Tutorials](https://nsidc.org/data/modis/ms2gt/tutorials.html) for more details. |
| *chanlist* | A string specifying channel numbers to be gridded. The default string is 1, i.e. grid channel 1 only. The channel numbers are:

-   1: Sea Ice by Reflectance - creates an icer output file containing 8-bit unsigned coded values. See the [MODIS/Terra Sea Ice Extent 5-Min L2 Swath 1km](https://nsidc.org/data/docs/daac/modis_v5/mod29_modis_terra_seaice_5min_swath_1km.gd.html) documentation for a table of coded values.
-   2: Sea Ice by Reflectance PixelQA - creates a irqa output file containing 8-bit unsigned coded values. See the [MODIS/Terra Sea Ice Extent 5-Min L2 Swath 1km](https://nsidc.org/data/docs/daac/modis_v5/mod29_modis_terra_seaice_5min_swath_1km.gd.html) documentation for a description of values.
-   3: Ice Surface Temperature - creates a temp output file containing 16-bit unsigned values representing kelvin * 100. Note that the 16-bit unsigned values should be divided by 100. Resulting values in the range 0-255 represent coded values, while 655.35 represents the fill value; all other values represent temperatures in kelvin. See the [MODIS/Terra Sea Ice Extent 5-Min L2 Swath 1km](https://nsidc.org/data/docs/daac/modis_v5/mod29_modis_terra_seaice_5min_swath_1km.gd.html) documentation for a table of coded values.
-   4: Ice Surface Temperature PixelQA - creates a itqa output file containing 8-bit unsigned coded values. See [MODIS Sea Ice Bit Processing](https://nsidc.org/data/docs/daac/mod29_modis_seaice/seaice_qa.html) for a description of values.

The *chanlist* string should not contain any embedded blanks. To specify that all channels should be gridded, set *chanlist* to 1234.\
NOTE: During twilight and nighttime conditions, dark [MOD29](https://nsidc.org/data/mod29v5.html) granules may be created that include neither Sea Ice by Reflectance nor Sea Ice by Reflectance PixelQA. Gridded arrays containing the fill value of 255 are returned when these channels are specified for dark [MOD29](https://nsidc.org/data/mod29v5.html) granules. |
| *latlonlistfile* | A text file containing a list of [MOD02HKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf), [MOD02QKM](http://ccplot.org/pub/resources/Aqua/MODIS%20Level%201B%20Product%20User%20Guide.pdf), or [MOD03](https://modis.gsfc.nasa.gov/data/dataprod/dataproducts.php?MOD_NUMBER=03) files whose latitude and longitude data should be used in place of the latitude and longitude data in the corresponding [MOD29](https://nsidc.org/data/mod29v5.html) files in listfile. The default is none, indicating that the latitude and longitude data in each [MOD29](https://nsidc.org/data/mod29v5.html) file should be used. |
| *keep* | A single character code indicating whether intermediate files should or should not be deleted. The codes are as follows:

-   0: delete intermediate chan, lat, lon, col, and row files. (This is the default).
-   1: do not delete intermediate chan, lat, lon, col, and row files.

 |
| *rind* | The number of pixels to add around the intermediate grid to eliminate holes in the final grid. The default is 50, which is adequate in most cases. If you see pixels being set to the fill value along the seam joining adjacent scenes, then you might try increasing the value of *rind*. |

### Version History

See [Version History for information on revisions made to the software.](https://nsidc.org/data/modis/ms2gt/version_history.html)
