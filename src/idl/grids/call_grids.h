/*======================================================================
 * call_grids.h - grid coordinate system parameters for call_grids.c
 *
 * 15-Mar-2001 Terry Haran tharan@colorado.edu 303-492-1847
 * National Snow & Ice Data Center, University of Colorado, Boulder
 *======================================================================*/
#ifndef call_grids_h_
#define call_grids_h_

static const char call_grids_h_rcsid[] = "$Header: /export/data/modis/src/idl/grids/call_grids.h,v 1.2 2001/03/20 23:54:40 haran Exp haran $";

/*
 * call_grid parameters structure
 */
typedef struct {
  IDL_LONG grid_class_ptr;      
  float map_origin_col, map_origin_row;
  float cols_per_map_unit, rows_per_map_unit;
  IDL_LONG cols, rows;
  IDL_STRING gpd_filename;
  float lat0, lon0, lat1, lon1;
  float rotation, scale;
  float south, north, west, east;
  float center_lat, center_lon, label_lat, label_lon;
  float lat_interval, lon_interval;
  IDL_LONG cil_detail, bdy_detail, riv_detail;
  double equatorial_radius, eccentricity;
  IDL_STRING projection_name;
} grid_class_struct;


/*
 * function prototypes
 */

long call_init_grid(short argc, void *argv[]);
long call_close_grid(short argc, void *argv[]);

#endif
