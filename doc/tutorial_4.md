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

## Tutorial 4: Gridding 1 km Sea Ice Data over the Ross Sea Using mod29.pl

*   [Requirements](#requirements)
*   [Searching for the Data](#search)
*   [Ordering and Downloading the Data](#order)
*   [Creating the mod29.pl Command File](#command)
*   [Creating the listfile](#listfile)
*   [Creating the gpd and mpp files](#gpdfile)
*   [Running the mod29.pl Command File](#running)
*   [Examining the Results](#examining)

## <a name="requirements"></a>Requirements

Suppose we want to put some MODIS 1 km sea ice swath data covering the western portion of the Ross Sea into a Polar Stereographic ellipsoidal projection centered at the south pole with the parallel of true scale set to 71 S. We want the vertical axis of the grid pointing due north towards the top of the grid and parallel to 180 E. We want the upper left corner of the grid at exactly 70 S 165 E and the lower right corner near 79 S 160 W. We want the grid resolution to be 1 km and we want to use the WGS84 ellipsoid (equatorial radius of 6378.137 km and an eccentricity of 0.081819190843). We want to grid all available [MOD29](/data/mod29.html) "channels." We could simply order [MOD29](/data/mod29.html) data; however, as we can see in [Supported Data Sets](index.html#datasets), the latlon data are stored at only 5 km resolution in [MOD29](/data/mod29.html) granules. We could have [mod29.pl](index.html#mod29) work with only the [MOD29](/data/mod29.html) granules (i.e. by setting latlonlistfile to "none"); we decide that 5 km resolution for the latlon data is good enough for our purposes, so we won't order any [MOD03](http://daac.gsfc.nasa.gov/CAMPAIGN_DOCS/MODIS/rad_geo/MOD03.shtml) granules.

NOTE: To run this example, you'll need a machine with at least 100 MB of memory and at least 200 MB of free disk space.

## <a name="search"></a>Searching for the Data

Let's assume that we happen to know that January 24, 2001 was fairly clear over the western Ross Sea and that there was a significant amount of sea ice present, so we use the [EDG](http://redhook.gsfc.nasa.gov/~imswww/pub/imswelcome/) to order two [MOD29](/data/mod29.html) granules acquired on January 24, 2001 at 1635 and 1640 that appear to cover the Ross Sea. You can use the following values for performing the search using the [EDG](http://redhook.gsfc.nasa.gov/~imswww/pub/imswelcome/):

Data Set  
<tt>MODIS/TERRA SEA ICE EXTENT 5-MIN L2 SWATH 1KM</tt>

Search Area  
Type in Lat/Lon Range:  
<tt>Northern latitude: -70.0000</tt>  
<tt>Southern latitude: -79.0000</tt>  
<tt>Western longitude: 165.0000</tt>  
<tt>Eastern longitude: -160.0000</tt>

<tt>Start Date: 2001-10-24  Time (UTC): 16:00:00</tt>  
<tt>End Date:   2001-10-24  Time (UTC): 17:00:00</tt>

The search should find two granules having the following names:  
<tt>                                                                                  MOD29.A2001024.1635.002.2001089060137.hdf</tt>  
<tt>MOD29.A2001024.1640.002.2001089060152.hdf</tt>

Note that January 24, 2001 is day-of-year 024.

## <a name="order"></a>Ordering and Downloading the Data

Order and download the above files to some directory we'll call the tutorial_4 directory where you have at least 200 MB of free disk space. Note that you can also download the *.met files that accompany the *.hdf files, but the MS2GT software doesn't use them.

## <a name="command"></a>Creating the mod29.pl Command File

Create a text file in the tutorial_4 directory called wross_2001024_1635.csh containing the following line:

<tt>mod29.pl . wross_2001024_1635 listfile.txt WRoss1km.gpd 123456</tt>

This command specifies the following information (see [mod29.pl](index.html#mod29)):

*   dirinout is "." indicating that the current directory in effect when wross_2001024_1635.csh is invoked will contain the input and output files.
*   tag is "wross_2001024_1635" indicating that all output filenames containing gridded data created by [mod29.pl](index.html#mod29) will begin with the string "wross_2001024_1635".
*   listfile is "listfile.txt" containing a list of the [MOD29](/data/mod29.html) files to be processed (see [Creating the listfile](#listfile)).
*   gpdfile is "WRoss1km.gpd" containing a specification of the grid and its associated map projection to use in gridding the data (see [Creating the gpd and mpp files](#gpdfile)).
*   chanlist is "123456" specifying that all the [MOD29](/data/mod29.html) "channels" should be gridded.
*   latlonlistfile is not specified, so the default value of "none" is used indicating that the 5 km latlon data in the [MOD29](/data/mod29.html) files should be used for geolocation.
*   keep is not specified, so the default value of "0" is used indicating that intermediate chan, lat, lon, col, and row files should be deleted.
*   rind is not specified, so the default value of "50" is used. If you see holes in the final grid that seem to correspond to the boundaries between adjacent swath granules, then you might try increasing the rind value.

Make wross_2001024_1635.csh executable by typing:

<tt>chmod +x wross_2001024_1635.csh</tt>

## <a name="listfile"></a>Creating the listfile

Create a text file called listfile.txt in the tutorial_4 directory containing the following two lines:

<tt>MOD29.A2001024.1635.002.2001089060137.hdf</tt>  
<tt>MOD29.A2001024.1640.002.2001089060152.hdf</tt>

Note that we list the [MOD29](/data/mod29.html) files to be gridded.

## <a name="gpdfile"></a>Creating the gpd and mpp files

See [Points, Pixels, Grids, and Cells](http://cires.colorado.edu/~knowlesk/ppgc.html#parameters) for a description of the gpd and mpp file formats used by the mapx library in defining a grid and its associated map projection. In [Tutorial 3](tutorial_3.html), we created gpd and mpp files from scratch, but we required an exact location for the center of the grid. Here we'll do something similar, but we'll specify an exact location for the center of the upper left cell. We'll start with creating the mpp file, which we'll call S_stereo.mpp, in the ms2gt/grids directory (or, if you don't want to type it in, copy S_stereo.mpp from the ms2gt/tutorial_4 directory to the ms2gt/grids directory):

<tt>Polar Stereographic ellipsoid</tt>  
<tt>-90.0 0.0 -71.0 lat0 lon0 lat1</tt>  
<tt>180.0           rotation</tt>  
<tt>100.0           scale (km/map unit)</tt>  
<tt>-90.00  0.00    center lat lon</tt>  
<tt>-90.00  -20.00  lat min max</tt>  
<tt>-180.00 180.00  lon min max</tt>  
<tt> 10.00 15.00    grid</tt>  
<tt>0.00    0.00    label lat lon</tt>  
<tt>1 0 0           cil bdy riv</tt>  
<tt>6378.137        Earth equatorial radius (km) -- wgs84</tt>  
<tt>0.081819190843  eccentricity -- wgs84</tt>

*   The first line specifies the projection we wish to use, namely Polar Stereographic. Since we specify ellipsoid, an ellipsoidal projection is used.
*   The first two values on the second line specify the map projection origin, namely the south pole. The third value specifies the latitude of true scale to be 71 S.
*   The third line specifies the rotation, namely 180 degrees. This will produce a map with the vertical axis of the grid pointing due north towards the top of the grid and parallel to 180 E.
*   The fourth line specifies an arbitrary scale for the map as opposed to the grid, which will be defined by the gpd file as grid cells per map unit. Here we define a map unit to be 100 km.
*   The fifth line specifies the center of the map which is usually (but not necessarily) the map projection origin. Here we simply set it equal to the map projection origin, namely the south pole.
*   The next five lines (the sixth through tenth lines) specify parameters that would be useful to programs that produce graphic overlays (see [Points, Pixels, Grids, and Cells](http://cires.colorado.edu/~knowlesk/ppgc.html#parameters)). They are not used by the MS2GT software, but they need to be present in the mpp file as place holders.
*   The eleventh line, if present, specifies the equatorial radius to use instead of the default 6371.228 km. Here we specify 6378.137 km, which is the equatorial radius of the WGS84 ellipsoid.
*   The twelfth line, if present, specifies the eccentricity to use for ellipsoidal projections instead of the default 0.082271673\. Here we specify 0.081819190843, which is the eccentricity of the WGS84 ellipsoid.

In preparing the gpd file which will define our grid, we will need to know following:

*   The name of the mpp file which will define our map, namely S_stereo.mpp.
*   The number of columns and rows. We don't know these yet, but we can calculate approximate values for both in the following way:
    *   There are about 40000 km / 360 degrees = 111 km/deg in longitude at the equator or in latitude anywhere.
    *   We want our grid to have 1 km per cell.
    *   We need to span about 35 degrees in longitude (165 E to 160 W) at about 75 S. This works out to about 35 deg * cos(-75 deg) * 111 km/deg / (1 km/cell) = 1006 cells in longitude = 1006 columns.
    *   We need to span about 9 degrees in latitude (70 S to 79 S). This works out to about 9 deg * 111 km/deg / (1 km/cell) = 999 cells in latitude = 999 rows.
    *   These are only approximate values. We will determine exact values below.
*   The number of grid cells per map unit. This is equal to 100 km/map unit / (1 km/cell) = 100 cells/map unit
*   The grid cell coordinates of the center of the map. Since we want the center of the upper left cell to be at exactly 70 S 165 E, we will initially make the grid cell coordinates of the center of the map to be 0 0 (i.e. the south pole). Then we will use gtest to determine the coordinates of 70 S 165 E. We will then set the grid cell coordinates of the center of the map to be the negative of these coordinates determined by gtest.

We now have all the information we need to create a preliminary gpd file which we'll call WRoss1km0.gpd in the ms2gt/grids directory (or, if you don't want to type it in, copy WRoss1km0.gpd from the ms2gt/tutorial_4 directory to the ms2gt/grids directory):

<tt>S_stereo.mpp    map projection parameters       # Western Ross Sea</tt>  
<tt>1006    999     columns rows                    # preliminary values</tt>  
<tt>100             grid cells per map unit         # 1 km</tt>  
<tt>0       0       origin column, row              # origin south pole initially</tt>

Once WRoss1km0.gpd has been created in the ms2gt/grids directory, we can use gtest to determine the negative grid coordinates of the center of the map:

**<tt>gtest</tt>**

<tt>enter .gpd file name: **WRoss1km0.gpd**</tt>  
<tt>> assuming old style fixed format file</tt>

<tt>gpd: WRoss1km0.gpd</tt>  
<tt>mpp:S_stereo.mpp</tt>

<tt>forward_grid:</tt>  
<tt>enter lat lon: **-70 165**</tt>  
<tt>col,row = -567.976929 -2119.718262    status = 0</tt>  
<tt>lat,lon = -70.000000 164.999985    status = 1</tt>  
<tt>enter lat lon:</tt>

<tt>inverse_grid:</tt>  
<tt>enter r s:</tt>

<tt>enter .gpd file name:</tt>

So we see that the grid cell coordinates of the center of the map should be column 567.976929 and row 2119.718262\. Edit WRoss1km0.gpd to create WRoss1km1.gpd in the ms2gt/grids directory where we have replaced the 0 values for origin with the above values (or, if you don't want to type it in, copy WRoss1km1.gpd from the ms2gt/tutorial_4 directory to the ms2gt/grids directory):

<tt>S_stereo.mpp    map projection parameters       # Western Ross Sea</tt>  
<tt>1006    999     columns rows                    # preliminary values</tt>  
<tt>100             grid cells per map unit         # 1 km</tt>  
<tt>567.976929 2119.718262     origin column, row</tt>

We still have only approximate values for the number of columns and rows. We use gtest again, this time with WRoss1km1.gpd, to find the grid coordinates of 79 S 160 W which will be close to the center of our lower right cell, and we'll use these grid coordinates to determine the final number of columns and rows for our grid:

**<tt>gtest</tt>**

<tt>enter .gpd file name: **WRoss1km1.gpd**</tt>  
<tt>> assuming old style fixed format file</tt>

<tt>gpd: WRoss1km1.gpd</tt>  
<tt>mpp:S_stereo.mpp</tt>

<tt>forward_grid:</tt>  
<tt>enter lat lon: **-79 -160**</tt>  
<tt>col,row = 977.960999 993.297119    status = 1</tt>  
<tt>lat,lon = -79.000000 -160.000000    status = 1</tt>  
<tt>enter lat lon:</tt>

<tt>inverse_grid:</tt>  
<tt>enter r s:</tt>

<tt>enter .gpd file name:</tt>

So we see that our grid should have round(977.96099) + 1 = 979 columns and round(993.297119) + 1 = 994 rows. Edit WRoss1km1.gpd to create the final gpd file which we'll call WRoss1km.gpd in the ms2gt/grids directory where we have replaced the preliminary numbers of columns and rows with the values 979 and 994, respectively (or, if you don't want to type it in, copy WRoss1km.gpd from the ms2gt/tutorial_4 directory to the ms2gt/grids directory):

<tt>S_stereo.mpp    map projection parameters       # Western Ross Sea</tt>  
<tt>979     994     columns rows                    # Polar Stereographic</tt>  
<tt>100             grid cells per map unit         # 1 km</tt>  
<tt>567.976929 2119.718262     origin column, row</tt>

We now use gtest a third and final time to check that the upper left and lower right corners of WRoss1km.gpd are where they should be:

**<tt>gtest</tt>**

<tt>enter .gpd file name: **WRoss1km.gpd**</tt>  
<tt>> assuming old style fixed format file</tt>

<tt>gpd: WRoss1km.gpd</tt>  
<tt>mpp:S_stereo.mpp</tt>

<tt>forward_grid:</tt>  
<tt>enter lat lon:</tt>

<tt>inverse_grid:</tt>  
<tt>enter r s: **0 0**</tt>  
<tt>lat,lon = -70.000000 164.999985    status = 1</tt>  
<tt>col,row = -0.000488 0.000000    status = 1</tt>  
<tt>enter r s: **978 993**</tt>  
<tt>lat,lon = -78.997337 -160.003098    status = 1</tt>  
<tt>col,row = 977.999878 993.000488    status = 1</tt>  
<tt>enter r s:</tt>

<tt>enter .gpd file name:</tt>

So we see that the upper left corner values of -70.000000 164.999985 are essentially the same as our target values of 70 S and 165 E and that the lower right corner values of -78.997337 -160.003098 are very close to our target values of 79 S and 160 W.

## <a name="running"></a>Running the mod29.pl Command File

Run the shell script containing the [mod29.pl](index.html#mod29) command by changing to the tutorial_4 directory, and then typing:

**<tt>wross_2001024_1635.csh</tt>**

You'll see lots of messages displayed while the [mod29.pl](index.html#mod29) script runs various IDL and C programs. In this example, the programs are:

1.  extract_chan - an IDL procedure for extracting channel data and optionally latlon data from a [MOD29](/data/mod29.html) file. This program calls another IDL procedure, modis_ice_read. In this example, extract_chan is called twelve times: six times for each of the two [MOD29](/data/mod29.html) files; on each call, channel 1, 2, 3, 4, 5, or 6 is extracted. One binary byte file is created per call containing the channel data. In addition, on the first call for each of the [MOD29](/data/mod29.html) files, the latitude and longitude data are extracted and two binary floating-point files are created per call containing latitude and longitude data, respectively. The [mod29.pl](index.html#mod29) script concatenates the two latitude files and the two longitude files to create a single latitude file and a single longitude file, and the pre-concatenated files are deleted. The [mod29.pl](index.html#mod29) script concatenates each pair of channel files, creates six concatenated channel files, and then deletes the pre-concatenated channel files.
2.  ll2cr - a C program for converting latitude, longitude pairs to column, row pairs for a particular grid. The grid specified in this example is WRoss1km.gpd. The concatenated latitude and longitude files are read and two binary floating-point files are created containing column and row numbers, respectively. The [mod29.pl](index.html#mod29) script then deletes the concatenated latitude and longitude files.
3.  interp_colrow - an IDL procedure for interpolating column, row pairs from a lower resolution swath format to a higher resolution swath format, in this case from 5 km to 1 km. The interpolation must be performed on a scan's worth of data at a time because the column and row numbers have discontinuities at scan boundaries. The interp_colrow procedure calls a function called congridx for each scan's worth of column and row arrays. The congridx function is called once for the column array and once for the row array. The congridx function first performs an extrapolation of the given array to a slightly expanded array, which it then interpolates (bilinear interpolation is used here) to a fully expanded array. The final array is extracted from the fully expanded array. The [mod29.pl](index.html#mod29) script then deletes the pre-interpolated column and row files.
4.  fornav - a C program for performing forward navigation from a swath to a grid. In this example, fornav is called six times, once for each of the six concatenated channel files. On each call, the column and row files are read as well. An elliptical weighted maximum algorithm is applied during forward navigation to minimize holes and aliasing in the gridded data. One binary byte file (or, in the case of channel 3 Ice Surface Temperature, one binary 2-byte unsigned integer file) is created per call containing the gridded data. The [mod29.pl](index.html#mod29) script then deletes the concatenated channel files as well as the column and row files.

The final message should contain the string:

<tt>MOD29: MESSAGE: done</tt>

## <a name="examining"></a>Examining the Results

Enter the command:

**<tt>ls -l *.img</tt>**

You should see something like this:

<tt>-rw-r--r--    1 haran    nsidc      973126 May  1 13:15 wross_2001024_1635_rawm_icer_00979_00994.img</tt>  
<tt>-rw-r--r--    1 haran    nsidc      973126 May  1 13:16 wross_2001024_1635_rawm_icet_00979_00994.img</tt>  
<tt>-rw-r--r--    1 haran    nsidc      973126 May  1 13:16 wross_2001024_1635_rawm_icrt_00979_00994.img</tt>  
<tt>-rw-r--r--    1 haran    nsidc      973126 May  1 13:16 wross_2001024_1635_rawm_irqa_00979_00994.img</tt>  
<tt>-rw-r--r--    1 haran    nsidc      973126 May  1 13:16 wross_2001024_1635_rawm_itqa_00979_00994.img</tt>  
<tt>-rw-r--r--    1 haran    nsidc     1946252 May  1 13:16 wross_2001024_1635_rawm_temp_00979_00994.img</tt>

Each of the first five files listed contains a gridded array of 979 columns and 994 rows of binary byte values (979 * 994 * 1 = 973126 bytes). The sixth file listed (the "temp" or Ice Surface Temperature file) contains a gridded array of 979 columns and 994 rows of binary 2-byte unsigned values (979 * 994 * 2 =  1946252 bytes).

The file naming convention for gridded [MOD29](/data/mod29.html) files is as follows:

<tag>_<conversion><weight_type>_<chan>_<columns>_<rows>.img

*   <tag> is the [mod29.pl](index.html#mod29) tag parameter
*   <conversion> is:
    *   raw - raw (1-byte and 2-byte unsigned integers)
*   <weight_type> is:
    *   m - maximum
*   <chan> is the channel name and is one of:
    *   icer - channel 1 - Sea Ice by Reflectance - 8-bit unsigned
        *   See [MODIS/Terra Sea Ice Extent L2 and L3 Day and Night 1 km](/data/docs/daac/mod29_modis_seaice.gd.html#integer_key) for a table of coded values.
    *   irqa - channel 2 - Sea Ice by Reflectance PixelQA - 8-bit unsigned
        *   See [MODIS Sea Ice Bit Processing](/data/docs/daac/mod29_modis_seaice/seaice_qa.html) for a description of values.
    *   temp - channel 3 - Ice Surface Temperature - 16-bit unsigned (kelvin * 100)
        *   Note that the 16-bit unsigned values should be divided by 100.
        *   Resulting values in the range 0-255 represent coded values while 655.35 represents the fill value; all other values represent temperatures in kelvin.
        *   See [MODIS/Terra Sea Ice Extent L2 and L3 Day and Night 1 km](/data/docs/daac/mod29_modis_seaice.gd.html#integer_key) for a table of coded values.
    *   itqa - channel 4 - Ice Surface Temperature PixelQA - 8-bit unsigned
        *   See [MODIS Sea Ice Bit Processing](/data/docs/daac/mod29_modis_seaice/seaice_qa.html) for a description of values.
    *   icet - channel 5 - Sea Ice by IST - 8-bit unsigned
        *   See [MODIS/Terra Sea Ice Extent L2 and L3 Day and Night 1 km](/data/docs/daac/mod29_modis_seaice.gd.html#integer_key) for a table of coded values.
    *   icrt - channel 6 - Combined Sea Ice - 8-bit unsigned
        *   See [MOD29 Local Attributes](/data/docs/daac/mod29_modis_seaice/mod29_local_attributes.html#mod29_csi) for a table of coded values.
*   <columns> is the number of columns in the grid
*   <rows> is the number of rows in the grid

* * *

Last updated: January 2, 2002 by  
Terry Haran  
NSIDC-CIRES  
449 UCB  
University of Colorado  
Boulder, CO 80309-0449  
303-492-1847  
[tharan@nsidc.org](mailto:tharan@nsidc.org)
