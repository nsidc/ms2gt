/*========================================================================
 * call_grids - IDL call_external interface to mapx library routines
 *
 * Functions in this file serve as an interface between IDL and mapx library
 * functions.
 * The functions contained here are:
 *   call_init_grid
 * 14-Mar-2001 Terry Haran tharan@colorado.edu 303-492-1847
 * National Snow & Ice Data Center, University of Colorado, Boulder
 *========================================================================*/
static const char call_grids_c_rcsid[] = "$Header: /export/data/modis/src/idl/grids/call_grids.c,v 1.3 2001/03/20 23:55:43 haran Exp haran $";

#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include "export.h"
#include "define.h"
#include "mapx.h"
#include "grids.h"
#include "call_grids.h"

/*------------------------------------------------------------------------
 * call_init_grid - call init_grid()
 *
 * This function is called from an IDL program with the following statement:
 * 
 * ERROR = call_external('call_grids.so', 'call_init_grid', $
 *                       gpd_filename, gcs)
 *
 *      input : gpd_filename - string containing the name of gpd filename
 *                  to be opened.
 *
 *      output: gcs - grid_class_struct structure to be initialized.
 *
 *      result: 1 if success.
 *              0 if error opening or initializing grid_class structure.
 *
 *------------------------------------------------------------------------*/

long call_init_grid(short argc, void *argv[])
{

  /*
   * parameters passed in from IDL
   */

  IDL_STRING *gpd_filename;
  grid_class_struct *gcs;
  
  /*
   * local parameters
   */

  grid_class *grid;
  mapx_class *mapx;
  
  /*
   * Check that correct number of parameters was passed
   */
  
  if (argc != 2)
    return 0;

  /*
   * Cast passed parameters to local vars
   */
  
  gpd_filename = (IDL_STRING *)argv[0];
  gcs = (grid_class_struct *)argv[1];
  
  /*
   * Call the function
   */

  grid = init_grid(gpd_filename->s);

  /*
   * Check that the grid was initialized successfully
   */

  if (grid == NULL)
    return 0;

  /*
   * Copy data from grid_class instance to grid_class_struct instance
   */

  gcs->grid_class_ptr = (IDL_LONG)grid;
  gcs->map_origin_col = grid->map_origin_col;
  gcs->map_origin_row = grid->map_origin_row;
  gcs->cols_per_map_unit = grid->cols_per_map_unit;
  gcs->rows_per_map_unit = grid->rows_per_map_unit;
  gcs->cols = grid->cols;
  gcs->rows = grid->rows;

  gcs->gpd_filename.s = grid->gpd_filename;
  gcs->gpd_filename.slen = strlen(grid->gpd_filename);

  mapx = grid->mapx;
  gcs->lat0 = mapx->lat0;
  gcs->lon0 = mapx->lon0;
  gcs->lat1 = mapx->lat1;
  gcs->lon1 = mapx->lon1;
  gcs->rotation = mapx->rotation;
  gcs->scale = mapx->scale;
  gcs->south = mapx->south;
  gcs->north = mapx->north;
  gcs->west = mapx->west;
  gcs->east = mapx->east;
  gcs->center_lat = mapx->center_lat;
  gcs->center_lon = mapx->center_lon;
  gcs->label_lat = mapx->label_lat;
  gcs->label_lon = mapx->label_lon;
  gcs->lat_interval = mapx->lat_interval;
  gcs->lon_interval = mapx->lon_interval;
  gcs->cil_detail = mapx->cil_detail;
  gcs->bdy_detail = mapx->bdy_detail;
  gcs->riv_detail = mapx->riv_detail;
  gcs->equatorial_radius = mapx->equatorial_radius;
  gcs->eccentricity = mapx->eccentricity;

  gcs->projection_name.s = mapx->projection_name;
  gcs->projection_name.slen = strlen(mapx->projection_name);
  
  return 1;
}


/*------------------------------------------------------------------------
 * call_close_grid - call close_grid()
 *
 * This function is called from an IDL program with the following statement:
 * 
 * ERROR = call_external('call_grids.so', 'call_close_grid', $
 *                       gcs)
 *
 *      input: gcs - grid_class_struct structure to be closed.
 *
 *      output: gcs - grid_class_struct structure after being closed.
 *
 *      result: 1 if success.
 *              0 if error closing grid_class structure.
 *
 *------------------------------------------------------------------------*/

long call_close_grid(short argc, void *argv[])
{

  /*
   * parameters passed in from IDL
   */

  grid_class_struct *gcs;
  
  /*
   * Check that correct number of parameters was passed
   */
  
  if (argc != 1)
    return 0;

  /*
   * Cast passed parameters to local vars
   */
  
  gcs = (grid_class_struct *)argv[0];
  
  /*
   * Call the function
   */

  close_grid((grid_class *)(gcs->grid_class_ptr));

  /*
   * Copy data from grid_class instance to grid_class_struct instance
   */

  gcs->grid_class_ptr = (IDL_LONG)0;
  gcs->map_origin_col = 0.0;
  gcs->map_origin_row = 0.0;
  gcs->cols_per_map_unit = 0.0;
  gcs->rows_per_map_unit = 0.0;
  gcs->cols = (IDL_LONG)0;
  gcs->rows = (IDL_LONG)0;

  gcs->gpd_filename.s = NULL;
  gcs->gpd_filename.slen = 0;

  gcs->lat0 = 0.0;
  gcs->lon0 = 0.0;
  gcs->lat1 = 0.0;
  gcs->lon1 = 0.0;
  gcs->rotation = 0.0;
  gcs->scale = 0.0;
  gcs->south = 0.0;
  gcs->north = 0.0;
  gcs->west = 0.0;
  gcs->east = 0.0;
  gcs->center_lat = 0.0;
  gcs->center_lon = 0.0;
  gcs->label_lat = 0.0;
  gcs->label_lon = 0.0;
  gcs->lat_interval = 0.0;
  gcs->lon_interval = 0.0;
  gcs->cil_detail = (IDL_LONG)0;
  gcs->bdy_detail = (IDL_LONG)0;
  gcs->riv_detail = (IDL_LONG)0;
  gcs->equatorial_radius = (double)0.0;
  gcs->eccentricity = (double)0.0;

  gcs->projection_name.s = NULL;
  gcs->projection_name.slen = 0;
  
  return 1;
}
