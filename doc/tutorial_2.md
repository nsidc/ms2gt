<table align="center" bgcolor="#003366" border="0" cellpadding="0" cellspacing="0" width="100%">

<tbody>

<tr>

<td>![NSIDC global navigation](http://nsidc.org/ssi/images/nsidc.gif) <map name="global_nav.map"> <area shape="rect" coords="1,1,82,17" href="http://nsidc.org/" alt="NSIDC home"> <area shape="rect" coords="119,1,153,17" href="http://nsidc.org/data/" alt="Data"> <area shape="rect" coords="169,1,225,17" href="http://nsidc.org/projects.html" alt="Projects"> <area shape="rect" coords="242,1,302,17" href="http://nsidc.org/research/" alt="Research"> <area shape="rect" coords="315,1,419,17" href="http://nsidc.org/cryosphere/" alt="Cryosphere"> <area shape="rect" coords="430,2,474,18" href="http://nsidc.org/news/" alt="News"> <area shape="rect" coords="485,1,546,17" href="http://nsidc.org/sitemap/" alt="Site map"></map></td>

</tr>

</tbody>

</table>

<table align="center" bgcolor="#FFFFFF" border="0" cellpadding="0" cellspacing="0" width="100%">

<tbody>

<tr>

<td>![Data section navigation](/ssi/images/data_core.gif) <map name="data_banner"> <area shape="rect" coords="79,9,171,24" href="http://nsidc.org/data/catalog.html" alt="NSIDC Data Catalog"> <area shape="rect" coords="185,10,230,24" href="http://nsidc.org/data/search.html" alt="Search the Data Catalog"> <area shape="rect" coords="290,7,319,24" href="http://nsidc.org/data/help/" alt="Data Help Center"> <area shape="rect" coords="242,8,278,25" href="http://nsidc.org/data/tools/" alt="Data Tools"> <area shape="rect" coords="334,7,386,24" href="http://nsidc.org/data/features.html" alt="Data Features"></map></td>

</tr>

</tbody>

</table>

[![NSIDC DAAC](/images/logo_nasa_daac_77x65.gif)](/daac/index.html)

### MODIS Data at NSIDC

* * *

<div class="SmallText">[Home](/data/modis/index.html)  |   [Data Summaries](/data/modis/data.html)  |   [CMG Browse](/data/modis/cmg_browse/index.html)  |   [Image Gallery](/data/modis/gallery/index.html)  |   [Order Data](/data/modis/order.html)  |   [News](/data/modis/news.html)  |   [FAQs](/data/modis/faq.html)</div>

* * *

## MS2GT: The MODIS Swath-to-Grid Toolbox

<div align="center" class="SmallText">*** Documentation for this product is in development. ***  
Please [contact NSIDC User Services](/forms/contact.html).</div>

* * *

## Tutorial 2: Gridding MODIS 250 m Level 1b Data over Greenland Using mod02.pl

*   [Requirements](#requirements)
*   [Searching for the Data](#search)
*   [Ordering and Downloading the Data](#order)
*   [Creating the mod02.pl Command File](#command)
*   [Creating the listfile](#listfile)
*   [Creating the gpd and mpp files](#gpdfile)
*   [Creating the chanfile](#chanfile)
*   [Running the mod02.pl Command File](#running)
*   [Examining the Results](#examining)

## <a name="requirements"></a>Requirements

Suppose we want to put some MODIS 250 m Level 1b swath data covering all of Greenland into the same grid used in [Tutorial 1](tutorial_1.html), except that we want to change the resolution of the grid from 1.25 km to 250 m. We want to grid reflective channels 1 and 2, which are the only MODIS channels available at 250m. We need to order [MOD02QKM](http://daac.gsfc.nasa.gov/CAMPAIGN_DOCS/MODIS/rad_geo/MOD02QKM.shtml) data; however, as we can see in [Supported Data Sets](index.html#datasets), the lat-lon data are stored at only 1 km resolution in [MOD02QKM](http://daac.gsfc.nasa.gov/CAMPAIGN_DOCS/MODIS/rad_geo/MOD02QKM.shtml) granules. Therefore, [mod02.pl](index.html#mod02) will need to interpolate the 1 km lat-lon data in the [MOD02QKM](http://daac.gsfc.nasa.gov/CAMPAIGN_DOCS/MODIS/rad_geo/MOD02QKM.shtml) granules to 250 m resolution. There is no need to work with [MOD03](http://daac.gsfc.nasa.gov/CAMPAIGN_DOCS/MODIS/rad_geo/MOD03.shtml) granules since the lat-lon data are also at 1 km resolution in [MOD03](http://daac.gsfc.nasa.gov/CAMPAIGN_DOCS/MODIS/rad_geo/MOD03.shtml) granules and we're not gridding any ancillary data.

NOTE: To run this example, you'll need a machine with at least 750 MB of memory and about 1.5 GB of free disk space.

## <a name="searching"></a>Searching for the Data

Let's assume that we want to use data from the same date and time as in [Tutorial 1](tutorial_1.html), except that this time we want to search for [MOD02QKM](http://daac.gsfc.nasa.gov/CAMPAIGN_DOCS/MODIS/rad_geo/MOD02QKM.shtml) granules rather than [MOD021KM](http://daac.gsfc.nasa.gov/CAMPAIGN_DOCS/MODIS/rad_geo/MOD021KM.shtml) and [MOD03](http://daac.gsfc.nasa.gov/CAMPAIGN_DOCS/MODIS/rad_geo/MOD03.shtml) granules. We use the [EDG](http://redhook.gsfc.nasa.gov/~imswww/pub/imswelcome/) to order two [MOD02QKM](http://daac.gsfc.nasa.gov/CAMPAIGN_DOCS/MODIS/rad_geo/MOD02QKM.shtml) granules acquired on June 1, 2000 at 1445 and 1450 that appear to cover Greenland. You can use the following values for performing the search using the [EDG](http://redhook.gsfc.nasa.gov/~imswww/pub/imswelcome/):

Data Set  
<tt>MODIS/TERRA CALIBRATED RADIANCES 5-MIN L1B SWATH 250M</tt>

Search Area  
Type in Lat/Lon Range:  
<tt>Northern latitude: 85.0000</tt>  
<tt>Southern latitude: 60.0000</tt>  
<tt>Western longitude: -80.0000</tt>  
<tt>Eastern longitude: 10.0000</tt>

<tt>Start Date: 2000-06-01  Time (UTC): 14:00:00</tt>  
<tt>End Date:   2000-06-01  Time (UTC): 15:00:00</tt>

The search should find two granules having the following names:

<tt>MOD02QKM.A2000153.1445.002.2000156075718.hdf</tt>  
<tt>MOD02QKM.A2000153.1450.002.2000156075717.hdf</tt>

Note that June 1, 2000 is day-of-year 153.

## <a name="order"></a>Ordering and Downloading the Data

Order and download the above files to some directory we'll call the tutorial_2 directory where you have at least 1.5 GB of free disk space. Note that you can also download the *.met files that accompany the *.hdf files, but the MS2GT software doesn't use them.

## <a name="command"></a>Creating the mod02.pl Command File

Create a text file in the tutorial_2 directory called gl250_2000153_1445.csh containing the following line:

<tt>mod02.pl . gl250_2000153_1445 listfile.txt Gl0250.gpd chanfile.txt none Q</tt>

This command specifies the following information (see [mod02.pl](index.html#mod02)):

*   dirinout is "." indicating that the current directory in effect when gl250_2000153_1445.csh is invoked will contain the input and output files.
*   tag is "gl250_2000153_1445" indicating that all output filenames containing gridded data created by [mod02.pl](index.html#mod02) will begin with the string "gl250_2000153_1445".
*   listfile is "listfile.txt" containing a list of the MOD02 files to be processed (see [Creating the listfile](#listfile)).
*   gpdfile is "Gl0250.gpd" containing a specification of the grid and its associated map projection to use in gridding the data (see [Creating the gpd and mpp files](#gpdfile)).
*   chanfile is "chanfile.txt" containing a list of the channels to be gridded as well as specifying how each channel should be processed (see [Creating the chanfile](#chanfile)).
*   ancilfile is "none" indicating that we do not wish to grid any ancillary data.
*   latlon_src is "Q" indicating that  the 1 km latitude and longitude data in the [MOD02QKM](http://daac.gsfc.nasa.gov/CAMPAIGN_DOCS/MODIS/rad_geo/MOD02QKM.shtml) files should be used.
*   ancil_src is not specified, and ancilfile is "none," so ancil_src is ignored.
*   keep is not specified, so the default value of "0" is used indicating that intermediate chan, lat, lon, col, and row files should be deleted.
*   rind is not specified, so the default value of "50" is used. If you see holes in the final grid that seem to correspond to the boundaries between adjacent swath granules, then you might try increasing the rind value.

Make gl250_2000153_1445.csh executable by typing:

<tt>chmod +x gl250_2000153_1445.csh</tt>

## <a name="listfile"></a>Creating the listfile

Create a text file called listfile.txt in the tutorial_2 directory containing the following two lines:

<tt>MOD02QKM.A2000153.1445.002.2000156075718.hdf</tt>  
<tt>MOD02QKM.A2000153.1450.002.2000156075717.hdf</tt>

Note that we list the [MOD02QKM](http://daac.gsfc.nasa.gov/CAMPAIGN_DOCS/MODIS/rad_geo/MOD02QKM.shtml) files to be gridded.

## <a name="gpdfile"></a>Creating the gpd and mpp files

Let's review the Gl1250.gpd file we created in [Tutorial 1](#gpdfile):

<tt>N200correct.mpp map projection parameters       # EASE-Grid</tt>  
<tt>1860 1740       columns rows                    # Greenland</tt>  
<tt>160             grid cells per map unit         # 1.25 km</tt>  
<tt>1949.5  -250.5  map origin column,row</tt>

We wish now to create Gl0250.gpd which will specify the same grid but at 250 m resolution rather than 1.25 km. The mpp file will be the same, namely [N200correct.mpp](/data/grids/N200correct.mpp). Note that 1250 / 250 = 5, so the number of columns and rows in Gl0250.gpd will be 5 * 1860 = 9300 columns and 5 * 1740 = 8700 rows. The grid cells per map unit will be 5 * 160 = 800\. The map origin column will be 5 * (1949.5 + 0.5) - 0.5 = 9749.5 and the map origin row will be 5 * (-250.5 + 0.5) - 0.5 = -1250.5\. We now have all the information we need to create Gl0250.gpd in the ms2gt/grids directory (if you don't want to type the file in, then just copy Gl0250.gpd from the ms2gt/tutorial_2 directory to the ms2gt/grids directory):

<tt>N200correct.mpp map projection parameters       # EASE-Grid</tt>  
<tt>9300 8700       columns rows                    # Greenland</tt>  
<tt>800             grid cells per map unit         # 250 m</tt>  
<tt>9749.5  -1250.5 map origin column,row</tt>

Once Gl0250.gpd has been created in the ms2gt/grids directory, we can use gtest again to check that the latitude and longitude values of the upper left and lower right corners match those in Gl1250.gpd:

**<tt>gtest</tt>**

<tt>enter .gpd file name: **Gl1250.gpd**</tt>  
<tt>> assuming old style fixed format file</tt>

<tt>gpd: /hosts/snow/AVHRR/pathfinder/grids/Gl1250.gpd</tt>  
<tt>mpp:/hosts/snow/AVHRR/pathfinder/grids/N200correct.mpp</tt>

<tt>forward_grid:</tt>  
<tt>enter lat lon:</tt>

<tt>inverse_grid:</tt>  
<tt>enter r s: **-0.5 -0.5**</tt>  
<tt>lat,lon = 67.700233 -82.694237    status = 1</tt>  
<tt>col,row = -0.500000 -0.499863    status = 1</tt>  
<tt>enter r s: **1859.5 1739.5**</tt>  
<tt>lat,lon = 67.400612 -2.589502    status = 1</tt>  
<tt>col,row = 1859.500000 1739.500000    status = 0</tt>  
<tt>enter r s:</tt>

<tt>enter .gpd file name: **Gl0250.gpd**</tt>  
<tt>> assuming old style fixed format file</tt>

<tt>gpd: Gl0250.gpd</tt>  
<tt>mpp:/hosts/snow/AVHRR/pathfinder/grids/N200correct.mpp</tt>

<tt>forward_grid:</tt>  
<tt>enter lat lon:</tt>

<tt>inverse_grid:</tt>  
<tt>enter r s: **-0.5 -0.5**</tt>  
<tt>lat,lon = 67.700233 -82.694237    status = 1</tt>  
<tt>col,row = -0.500000 -0.499390    status = 1</tt>  
<tt>enter r s: **9299.5 8699.5**</tt>  
<tt>lat,lon = 67.400612 -2.589502    status = 1</tt>  
<tt>col,row = 9299.500000 8699.500000    status = 0</tt>  
<tt>enter r s:</tt>

<tt>enter .gpd file name:</tt>

Note that we used **-0.5 -0.5** to specify the upper left corner of the upper left pixel (rather than **0 0** which would be the center of the upper left pixel) for both Gl1250.gpd and Gl0250.gpd, and that the resulting latitude and longitude values were the same, namely 67.700233 N and 82.694237 W, respectively. Similarly, we used **1859.5 1739.5** for the lower right corner of the lower right pixel for Gl1250.gpd and **9299.5 8699.5** for the lower right corner of the lower right pixel for Gl0250.gpd, and that the resulting latitude and logitude values were the same, namely 67.400612 N and 2.589502 W, respectively.

## <a name="chanfile"></a>Creating the chanfile

Create a text file in the tutorial_2 directory called chanfile.txt containing the following two lines:

<tt>1 reflectance</tt>  
<tt>2 reflectance</tt>

Here we specify that we want two output grids to be created containing channel 1 reflectance and channel 2 reflectance, respectively. Each file will consist of an array of binary floating-point numbers. Since we didn't specify weight type or fill, they are set to their default values, namely "avg" and "0".

## <a name="running"></a>Running the mod02.pl Command File

Run the shell script containing the [mod02.pl](index.html#mod02) command by changing to the tutorial_2 directory, and then typing:

**<tt>gl250_2000153_1445.csh</tt>**

You'll see lots of messages displayed while the [mod02.pl](index.html#mod02) script runs various IDL and C programs. In this example, the programs include:

1.  extract_latlon - an IDL procedure for extracting latitude and longitude data from a MOD02 or [MOD03](http://daac.gsfc.nasa.gov/CAMPAIGN_DOCS/MODIS/rad_geo/MOD03.shtml) file. This program calls another IDL procedure, modis_ancillary_read. In this example, extract_latlon is called twice, once for each of the two [MOD02QKM](http://daac.gsfc.nasa.gov/CAMPAIGN_DOCS/MODIS/rad_geo/MOD02QKM.shtml) files. Two binary floating-point files are created per call containing latitude and longitude data, respectively. The [mod02.pl](index.html#mod02) script concatenates the two latitude files and the two longitude files to create a single latitude file and a single longitude file, and the pre-concatenated files are deleted.
2.  ll2cr - a C program for converting latitude, longitude pairs to column, row pairs for a particular grid. The grid specified in this example is Gl0250.gpd. The concatenated latitude and longitude files are read and two binary floating-point files are created containing column and row numbers, respectively. The [mod02.pl](index.html#mod02) script then deletes the concatenated latitude and longitude files.
3.  interp_colrow - an IDL procedure for interpolating column, row pairs from a lower resolution swath format to a higher resolution swath format, in this case from 1 km to 250 m. The interpolation must be performed on a scan's worth of data at a time because the column and row numbers have discontinuities at scan boundaries. The interp_colrow procedure calls a function called congridx for each scan's worth of column and row arrays. The congridx function is called once for the column array and once for the row array. The congridx function first performs an extrapolation of the given array to a slightly expanded array, which it then interpolates (bicubic interpolation is used here) to a fully expanded array. The final array is extracted from the fully expanded array. The [mod02.pl](index.html#mod02) script then deletes the pre-interpolated column and row files.
4.  extract_chan - an IDL procedure for extracting channel data from a MOD02 file. This program calls another IDL procedure, modis_level1b_read. In this example, extract_chan is called two times, once for each of the two [MOD02QKM](http://daac.gsfc.nasa.gov/CAMPAIGN_DOCS/MODIS/rad_geo/MOD02QKM.shtml) files; on each call, channel 1 or channel 2 is extracted, and the result is converted to reflectance. One binary floating-point file is created per call containing the channel data. The [mod02.pl](index.html#mod02) script concatenates the pair of channel files, creates one concatenated channel file, and then deletes the pre-concatenated channel files.
5.  fornav - a C program for performing forward navigation from a swath to a grid. In this example, fornav is called two times, once for each of the two concatenated channel files. On each call, the interpolated column and row files are read as well. An elliptical weighted averaging algorithm is applied during forward navigation to minimize holes and aliasing in the gridded data. One binary floating-point file is created per call containing the gridded data. The [mod02.pl](index.html#mod02) script then deletes the concatenated channel files as well as the interpolated column and row files.

The final message should contain the string:

<tt>MOD02: MESSAGE: done</tt>

## <a name="examining"></a>Examining the Results

Enter the command:

**<tt>ls -l *.img</tt>**

You should see something like this:

<tt>-rw-r--r--    1 haran    nsidc     323640000 Apr 23 13:26 gl250_2000153_1445_refa_ch01_09300_08700.img</tt>  
<tt>-rw-r--r--    1 haran    nsidc     323640000 Apr 23 13:29 gl250_2000153_1445_refa_ch02_09300_08700.img</tt>

Each file contains a gridded array of 9300 columns and 8700 rows of binary floating-point values (9300 * 8700 * 4 = 323640000 bytes).

The file naming convention for gridded channel files can be found in [Tutorial 1](tutorial_1.html#examining).

* * *

Last updated: January 2, 2002 by  
Terry Haran  
NSIDC-CIRES  
449 UCB  
University of Colorado  
Boulder, CO 80309-0449  
303-492-1847  
[tharan@nsidc.org](mailto:tharan@nsidc.org)
