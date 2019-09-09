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

## MS2GT Tutorials

The best way to learn how to use MS2GT is to work through some examples.

In each of the following tutorials, you will need to order some MODIS data using a tool such as the [Earth Observing System (EOS) Data Gateway (EDG)](http://redhook.gsfc.nasa.gov/~imswww/pub/imswelcome/). Detailed instructions for using the [EDG](http://redhook.gsfc.nasa.gov/~imswww/pub/imswelcome/) are not provided in the tutorials found here; however [a tutorial for using the EDG is available online](http://redhook.gsfc.nasa.gov/~imswww/Tutorial/main.html).

The MS2GT software uses the [mapx library](http://cires.colorado.edu/~knowlesk/ppgc.html) to define grids for various map projection. This library reads two kinds of text files called [gpd and mpp](http://cires.colorado.edu/~knowlesk/ppgc.html#parameters) files that define a grid and a map projection, respectively. Pre-existing gpd and mpp files referred to in the tutorials can be found in the ms2gt/grids directory.

Each tutorial has a corresponding directory under ms2gt. These directories contain the text files (including any gpd and mpp files) created in in the particular tutorial to save you the trouble of typing them in.

*   [Tutorial 1: Gridding 1 km Level 1b Data over Greenland Using mod02.pl](tutorial_1.md)
*   [Tutorial 2: Gridding 250 m Level 1b Data over Greenland Using mod02.pl](tutorial_2.md)
*   [Tutorial 3: Gridding 500 m Snow Cover Data over Colorado US Using mod10_l2.pl](tutorial_3.md)
*   [Tutorial 4: Gridding 1 km Sea Ice Data over the Ross Sea Using mod29.pl](tutorial_4.md)

* * *

Last updated: January 2, 2002 by  
Terry Haran  
NSIDC-CIRES  
449 UCB  
University of Colorado  
Boulder, CO 80309-0449  
303-492-1847  
[tharan@nsidc.org](mailto:tharan@nsidc.org)
