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
static const char call_grids_c_rcsid[] = "$Header: /export/data/modis/src/idl/grids/call_grids.c,v 1.2 2001/03/20 21:55:23 haran Exp haran $";

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

  gcs->grid_class_ptr = (int)grid;
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
