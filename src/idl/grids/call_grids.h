/*======================================================================
 * call_grids.h - grid coordinate system parameters for call_grids.c
 *
 * 15-Mar-2001 Terry Haran tharan@colorado.edu 303-492-1847
 * National Snow & Ice Data Center, University of Colorado, Boulder
 *======================================================================*/
#ifndef call_grids_h_
#define call_grids_h_

static const char call_grids_h_rcsid[] = "$Header: /export/data/ms2gth/src/idl/grids/call_grids.h,v 1.5 2003/04/28 22:10:54 haran Exp $";

/*
 * call_grid parameters structure
 */
typedef struct {
  IDL_LONG grid_class_ptr;      
  double map_origin_col, map_origin_row;
  double cols_per_map_unit, rows_per_map_unit;
  IDL_LONG cols, rows;
  IDL_STRING gpd_filename;
  double lat0, lon0, lat1, lon1;
  double rotation, scale;
  double south, north, west, east;
  double center_lat, center_lon, label_lat, label_lon;
  double lat_interval, lon_interval;
  IDL_LONG cil_detail, bdy_detail, riv_detail;
  double equatorial_radius, polar_radius, eccentricity, eccentricity_squared;
  double x0, y0, false_easting, false_northing;
  double center_scale;
  IDL_LONG utm_zone;
  IDL_LONG isin_nzone, isin_justify;
  IDL_STRING projection_name;
} grid_class_struct;


/*
 * function prototypes
 */

long call_init_grid(short argc, void *argv[]);
long call_forward_grid(short argc, void *argv[]);
long call_inverse_grid(short argc, void *argv[]);
long call_close_grid(short argc, void *argv[]);

#endif
