/*========================================================================
 * lle2cre - convert latitude, longitude, elevation to column, row, elevation
 *
 * 26-Nov-2001 T.Haran tharan@kryos.colorado.edu 303-492-1847
 * National Snow & Ice Data Center, University of Colorado, Boulder
 *========================================================================*/
static const char lle2cre_c_rcsid[] = "$Header: /usr/people/haran/photoclin/src/lle2cre/lle2cre.c,v 1.3 2001/12/02 21:25:42 haran Exp $";

#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include "define.h"
#include "mapx.h"
#include "grids.h"
#include "matrix.h"

#define USAGE \
"usage: lle2cre [-v] [-g gpdfile]\n"\
"       default:         Sa0.gpd\n"\
"               [-c col_start row_start cols rows corfile]\n"\
"               <filein >fileout\n"\
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
" option: v - verbose\n"\
"         g gpdfile - defines the grid used to map latitude-longitude\n"\
"             pairs to column-row pairs. The default value of gpdfile is\n"\
"             Sa0.gpd.\n"\
"         c col_start row_start cols rows corfile - defines a sub-region\n"\
"             in the grid defined by gpdfile and an associated correction\n"\
"             file containing a 4-byte floating image. Each column-row\n"\
"             pair is used to look-up the nearest neighbor correction value\n"\
"             from corfile. The correction value is then added to elevation\n"\
"             before it is written to stdout. If the column-row pair falls\n"\
"             outside the sub-region, then the point is not written.\n"\
"\n"

static void DisplayUsage(void)
{
  error_exit(USAGE);
}

static void DisplayInvalidParameter(char *param)
{
  fprintf(stderr, "lle2cre: Parameter %s is invalid.\n", param);
  DisplayUsage();
}

main (int argc, char *argv[])
{
  bool verbose;
  char *option;
  char *gpdfile;
  int col_start;
  int row_start;
  int cols;
  int rows;
  char *corfile;
  bool do_correction;
  char line[MAX_STRING];
  int count_input;
  int count_output;
  double col;
  double row;
  double elev;
  float lat;
  float lon;
  grid_class *grid_def;
  int status;
  int bytes_per_cell;
  int bytes_per_row;
  float **correction;
  int jcol;
  int irow;
  FILE *fp_cor;
  bool in_region;

/*
 *	set defaults
 */
  verbose = FALSE;
  gpdfile = "Sa0.gpd";
  do_correction = FALSE;

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
 	if (argc <= 0)
	  DisplayInvalidParameter("gpdfile");
	gpdfile = *argv;
	break;
      case 'c':
	do_correction = TRUE;
	++argv; --argc;
	if (argc <= 0)
	  DisplayInvalidParameter("col_start");
	if (sscanf(*argv, "%d", &col_start) != 1)
	  DisplayInvalidParameter("col_start");
 	++argv; --argc;
	if (argc <= 0)
	  DisplayInvalidParameter("row_start");
	if (sscanf(*argv, "%d", &row_start) != 1)
	  DisplayInvalidParameter("row_start");
	++argv; --argc;
	if (argc <= 0)
	  DisplayInvalidParameter("cols");
	if (sscanf(*argv, "%d", &cols) != 1)
	  DisplayInvalidParameter("cols");
	++argv; --argc;
	if (argc <= 0)
	  DisplayInvalidParameter("rows");
	if (sscanf(*argv, "%d", &rows) != 1)
	  DisplayInvalidParameter("rows");
	++argv; --argc;
 	if (argc <= 0)
	  DisplayInvalidParameter("corfile");
	corfile = *argv;
	break;
    default:
	fprintf(stderr,"invalid option %c\n", *option);
	DisplayUsage();
      }
    }
  }

/*
 *	get command line arguments
 */
  if (argc != 0)
    DisplayUsage();

  if (verbose) {
    fprintf(stderr, "lle2cre: %s\n", lle2cre_c_rcsid);
    fprintf(stderr, "  gpdfile   = %s\n", gpdfile);
    if (do_correction) {
      fprintf(stderr, "  col_start = %d\n", col_start);
      fprintf(stderr, "  row_start = %d\n", row_start);
      fprintf(stderr, "  cols      = %d\n", cols);
      fprintf(stderr, "  rows      = %d\n", rows);
      fprintf(stderr, "  corfile   = %s\n", corfile);
    }
  }

  /*
   *  initialize grid
   */

  grid_def = init_grid(gpdfile);
  if (NULL == grid_def)
    exit(ABORT);

  if (do_correction) {
    /*
     *  allocate memory for correction
     */
    
    bytes_per_cell = sizeof(float);
    if ((correction =
	 (float **)matrix(rows, cols, bytes_per_cell, 1)) == NULL) {
      fprintf(stderr, "cr2cre: error allocating memory for correction");
      perror("lle2cre");
      error_exit("lle2cre");
    }
    
    /*
     *  read in entire correction
     */
    
    if ((fp_cor = fopen(corfile, "r")) == NULL) {
      fprintf(stderr, "lle2cre: error opening %s\n", corfile);
      perror("lle2cre");
      error_exit("lle2cre");
    }
    bytes_per_row = bytes_per_cell * cols;
    if (fread(&correction[0][0], bytes_per_row, rows, fp_cor) != rows) {
      fprintf(stderr, "lle2cre: error reading %s\n", corfile);
      perror("lle2cre");
      error_exit("lle2cre");
    }
    fclose(fp_cor);
  }

  count_input = 0;
  count_output = 0;
  while (fgets(line, sizeof(line), stdin)) {

    /*
     *  read and parse input line
     */

    count_input++;
    if (sscanf(line, "%f%f%lf", &lat, &lon, &elev) != 3) {
      fprintf(stderr, "error parsing input line %d:\n%s\n", count_input, line);
    } else {

      /*
       *  convert lat-lon pair to col-row pair
       */
      
      status = forward_grid(grid_def, lat, lon, &col, &row);
      if (status == 0) {
	fprintf(stderr, "Error mapping lat-lon to col-row on line %d:\n",
		count_input);
	fprintf(stderr, "  %s\n", line);
      }
      in_region = TRUE;
      
      /*
       *  perform correction as needed
       */
      
      if (do_correction) {
	irow = (int)(row - row_start + 0.5);
	jcol = (int)(col - col_start + 0.5);
	if (irow >= 0 && irow < rows &&
	    jcol >= 0 && jcol < cols) {
	  elev += correction[irow][jcol];
	} else {
	  in_region = FALSE;
	}
      }
      
      /*
       *  write output line
       */
      
      if (in_region) {
	printf("%11.5lf %11.5lf %11.6lf\n", col, row, elev);
	count_output++;
      }
    }
  }

  /*
   *  close grid
   */

  close_grid(grid_def);

  /*
   *  deallocate memory for correction
   */

  if (do_correction)
    free(correction);

  /*
   *  print number of lines processed
   */

  if (verbose) {
    fprintf(stderr, "  %d lines input\n", count_input);
    fprintf(stderr, "  %d lines output\n", count_output);
  }
  exit(EXIT_SUCCESS);
}
