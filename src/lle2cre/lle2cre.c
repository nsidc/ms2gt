/*========================================================================
 * lle2cre - convert latitude, longitude, elevation to column, row, elevation
 *
 * 26-Nov-2001 T.Haran tharan@kryos.colorado.edu 303-492-1847
 * National Snow & Ice Data Center, University of Colorado, Boulder
 *========================================================================*/
static const char lle2cre_c_rcsid[] = "$Header: /usr/people/haran/photoclin/src/lle2cre/lle2cre.c,v 1.2 2001/11/26 17:41:29 haran Exp $";

#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include "define.h"
#include "mapx.h"
#include "grids.h"

#define usage \
"usage: lle2cre [-v] [-g gpdfile] <filein >fileout\n"\
"       default:         Sa0.gpd\n"\
"\n"\
" input : filein (from stdin)\n"\
"         Each line of stdin must contain three ASCII fields representing\n"\
"         a measured elevation as follows:\n"\
"           latitude longitude elevation\n"\
"           where:\n"\
"             latitude is geographic (i.e. relative to ellipsoid) latitude\n"\
"               in degrees.\n"\
"             longitude is longitude in degrees.\n"\
"             elevation is elevation above wgs84 ellipsoid in meters.\n"\
"\n"\
" output: fileout (to stdout)\n"\
"           Each line of input creates a single line of\n"\
"           output containing the following three ASCII fields:\n"\
"             column row elevation\n"\
"               where:\n"\
"                 column is a column number in the defined grid.\n"\
"                 row is a row number in the defined grid.\n"\
"                 elevation is elevation above wgs84 ellipsoid in meters.\n"\
"\n"\
"\n"\
" option: v - verbose\n"\
"         g gpdfile - defines the grid used to map latitude, longitude pairs to\n"\
"             column, row pairs. The default value of gpdfile is Sa0.gpd.\n"\
"\n"

main (int argc, char *argv[])
{
  bool verbose;
  char *option;
  char *gpdfile;
  char line[MAX_STRING];
  int count;
  float col;
  float row;
  double elev;
  float lat;
  float lon;
  grid_class *grid_def;
  int status;

/*
 *	set defaults
 */
  verbose = FALSE;
  gpdfile = "Sa0.gpd";

/* 
 *	get command line options
 */
  while (--argc > 0 && (*++argv)[0] == '-') {
    for (option = argv[0]+1; *option != '\0'; option++) {
      switch (*option) {
      case 'v':
	verbose = TRUE;
	break;
      case 'g':
	++argv; --argc;
	gpdfile = *argv;
	break;
      default:
	fprintf(stderr,"invalid option %c\n", *option);
	error_exit(usage);
      }
    }
  }

/*
 *	get command line arguments
 */
  if (argc != 0)
    error_exit(usage);

  if (verbose) {
    fprintf(stderr, "lle2cre:\n");
    fprintf(stderr, "  gpdfile = %s\n", gpdfile);
  }

  /*
   *  initialize grid
   */

  grid_def = init_grid(gpdfile);
  if (NULL == grid_def)
    exit(ABORT);

  count = 0;
  while (fgets(line, sizeof(line), stdin)) {

    /*
     *  read and parse input line
     */

    if (sscanf(line, "%f%f%lf", &lat, &lon, &elev) != 3) {
      fprintf(stderr, "error parsing input line:\n%s\n", line);
      exit(ABORT);
    }

    /*
     *  convert lat-lon pair to col-row pair
     */

    status = forward_grid(grid_def, lat, lon, &col, &row);
    if (status == 0) {
      fprintf(stderr, "Error mapping lat-lon to col-row on line %d:\n", count);
      fprintf(stderr, "  %s\n", line);
    }

    /*
     *  write output line
     */
    
    printf("%11.5f %11.5f %11.6lf\n", col, row, elev);
    count++;
  }

  /*
   *  close grid
   */

  close_grid(grid_def);

  /*
   *  print number of lines processed
   */

  if (verbose)
    fprintf(stderr, "%d lines processed\n", count);
}
