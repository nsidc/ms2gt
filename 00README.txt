Readme for MODIS Swath-to-Grid Toolbox 0.2 --  27 April 2001
Terry Haran
National Snow and Ice Data Center
tharan@colorado.edu
303-492-1847

The MODIS Swath-to-Grid Toolbox (MS2GT) is a set of software tools that
can be used to read HDF-EOS files containing MODIS swath data and produce
flat binary files containing gridded data in a variety of map
projections. Multiple input files corresponding to successively acquired 5
minute MODIS "scenes" can be processed together to produce a seamless
output grid.

MS2GT consists of three perl programs that make calls to several
standalone IDL and C programs. The three perl programs read MOD02 Level 1b
files (mod02.pl), MOD10_L2 snow cover files (mod10_l2.pl), and MOD29 sea
ice files (mod29.pl).  All three Perl programs can optionally read MOD03
files for geolocation and/or ancillary data. User-specified swath data
arrays are read out of HDF-EOS files using a suite of IDL programs written
by Liam Gumley of SSEC at the University of Washington. During this step,
radiance data can be left as raw integer counts or converted to
floating-point corrected counts, radiances, or reflectances; similarly,
thermal data can be left as raw counts or converted to temperatures. These
swath data arrays, including latitude and longitude arrays, are saved as
temporary data files. The latitude and longitude files are then converted
to files containing column and row numbers of the target grid by a C
program called ll2cr which uses the mapx C library written by Ken Knowles
of NSIDC. The mapx library requires the use of a user-supplied Grid
Parameters Definition (.gpd) text file that specifies the desired grid and
associated map projection.  The column and row files and any ancillary
data files are then interpolated to the resolution of the primary data
files (1 km for MOD021KM and MOD29, 500 m for MOD02HKM and MOD10_L2, or
250 m for MOD02QKM) as necessary using two IDL programs (iterp_colrow.pro
and interp_swath.pro). Finally, the interpolated column and row files,
together with the primary data files and any interpolated ancillary data
files are run through a C program called fornav that performs forward
navigation to produce gridded flat binary files. The user can specify that
either elliptical weighted averaging or elliptical maximum weight sampling
be used during forward navigation.

MS2GT has been developed and tested on an SGI O2 workstation having 192
Mbytes of memory and running IRIX 6.5, perl 5.004_04, and IDL 5.3. Care
has been taken to minimize memory requirements at the expense of increased
temporary disk storage requirements and slightly slower speed. The result
is that fairly large gridded images can be created on a machine with a
modest amount of memory in a fairly short time. For example, the creation
of two 1316x1384 250 m grids containing MODIS channels 1 and 2 reflectance
data derived from a single MOD02QKM file takes about three minutes on the
above machine.

The software and associated documentation can be downloaded
from ftp://baikal.colorado.edu/pub/NSIDC/ms2gt0.2.tar.gz. Save this file in
some directory and type:

gunzip ms2gt0.2.tar.gz
tar xvf ms2gt0.2.tar 

This will create a directory called ms2gt in the current directory
containing several subdirectories. Further instructions on the
installation and use of MS2GT can be then found in html files in the
ms2gt/doc subdirectory. Point your browser to ms2gt/doc/index.html.
