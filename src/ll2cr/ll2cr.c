/*========================================================================
 * ll2cr - convert latitude-longitude pairs to column-row pairs
 *
 * 23-Oct-2000 Terry Haran tharan@colorado.edu 303-492-1847
 * National Snow & Ice Data Center, University of Colorado, Boulder
 *========================================================================*/
static const char ll2xy_c_rcsid[] = "$Header: /export/data/modis/src/ll2cr/ll2cr.c,v 1.1 2000/10/23 17:42:39 haran Exp haran $";

#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include "define.h"
#include "mapx.h"
#include "grids.h"

#define usage \
"usage: ll2cr [-v] colsin rowsin latfile lonfile gpdfile colfile rowfile\n"\
"\n"\
" input : colsin  - number of columns in each input file\n"\
"         rowsin  - number of rows in each input file\n"\
"         latfile - grid of 4 byte floating-point latitudes\n"\
"         lonfile - grid of 4 byte floating-point longitudes\n"\
"         gpdfile - grid parameters definition file\n"\
"\n"\
" output: colfile - grid of 4 byte floating-point column numbers\n"\
"         rowfile - grid of 4 byte floating-point row numbers\n"\
"\n"\
" options:v - verbose\n"\
"\n"

main (int argc, char *argv[])
{
  int colsin;
  int rowsin;
  char *latfile;
  char *lonfile;
  char *gpdfile;
  char *colfile;
  char *rowfile;
  char *option;
  bool verbose;

  FILE *fp_lat;
  FILE *fp_lon;
  FILE *fp_col;
  FILE *fp_row;
  float *lat_data;
  float *lon_data;
  float *col_data;
  float *row_data;
  int bytes_per_row;
  int row;
  int col;
  int status;
  grid_class *grid_def;

/*
 *	set defaults
 */
  verbose = FALSE;

/* 
 *	get command line options
 */
  while (--argc > 0 && (*++argv)[0] == '-')
  { for (option = argv[0]+1; *option != '\0'; option++)
    { switch (*option)
      { case 'v':
	  verbose = TRUE;
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
  if (argc != 7)
    error_exit(usage);

  colsin = atoi(*argv++);
  rowsin = atoi(*argv++);
  latfile = *argv++;
  lonfile = *argv++;
  gpdfile = *argv++;
  colfile = *argv++;
  rowfile = *argv++;

  if (verbose) {
    fprintf(stderr, "ll2cr:\n");
    fprintf(stderr, "  colsin  = %d\n", colsin);
    fprintf(stderr, "  rowsin  = %d\n", rowsin);
    fprintf(stderr, "  latfile = %s\n", latfile);
    fprintf(stderr, "  lonfile = %s\n", lonfile);
    fprintf(stderr, "  gpdfile = %s\n", gpdfile);
    fprintf(stderr, "  colfile = %s\n", colfile);
    fprintf(stderr, "  rowfile = %s\n", rowfile);
  }
  
  /*
   *  open input files
   */

  if ((fp_lat = fopen(latfile, "r")) == NULL) {
    fprintf(stderr, "ll2cr: error opening %s for reading\n", latfile);
    perror("ll2cr");
    exit(ABORT);
  }
  if ((fp_lon = fopen(lonfile, "r")) == NULL) {
    fprintf(stderr, "ll2cr: error opening %s for reading\n", lonfile);
    perror("ll2cr");
    exit(ABORT);
  }

  /*
   *  initialize grid
   */

  grid_def = init_grid(gpdfile);
  if (NULL == grid_def)
    exit(ABORT);

  /*
   *  open output files
   */

  if ((fp_col = fopen(colfile, "w")) == NULL) {
    fprintf(stderr, "ll2cr: error opening %s for writing\n", colfile);
    perror("ll2cr");
    exit(ABORT);
  }
  if ((fp_row = fopen(rowfile, "w")) == NULL) {
    fprintf(stderr, "ll2cr: error opening %s for writing\n", rowfile);
    perror("ll2cr");
    exit(ABORT);
  }

/*
 *	allocate storage for data grids
 */
  bytes_per_row = colsin * sizeof(float);

  lat_data = (float *)malloc(bytes_per_row);
  if (NULL == lat_data) {
    fprintf(stderr, "ll2cr: can't allocate memory for lat_data\n"); 
    perror("ll2cr");
    exit(ABORT);
  }
  lon_data = (float *)malloc(bytes_per_row);
  if (NULL == lon_data) {
    fprintf(stderr, "ll2cr: can't allocate memory for lon_data\n"); 
    perror("ll2cr");
    exit(ABORT);
  }
  col_data = (float *)malloc(bytes_per_row);
  if (NULL == col_data) {
    fprintf(stderr, "ll2cr: can't allocate memory for col_data\n"); 
    perror("ll2cr");
    exit(ABORT);
  }
  row_data = (float *)malloc(bytes_per_row);
  if (NULL == row_data) {
    fprintf(stderr, "ll2cr: can't allocate memory for row_data\n"); 
    perror("ll2cr");
    exit(ABORT);
  }

/*
 *  for each row in the input files 
 */
  for (row = 0; row < rowsin; row++) {

    /*
     *  read a row of latitudes and longitudes
     */
    if (fread(lat_data, bytes_per_row, 1, fp_lat) != 1) {
      fprintf(stderr, "ll2rc: premature end of file on %s\n", latfile);
      exit(ABORT);
    }
    if (fread(lon_data, bytes_per_row, 1, fp_lon) != 1) {
      fprintf(stderr, "ll2rc: premature end of file on %s\n", lonfile);
      exit(ABORT);
    }

    /*
     *  for each column of latitude-longitude pair
     */
    for (col = 0; col < colsin; col++) {
      
      /*
       *  convert latitude-longitude pair to column-row pair
       */
      status = forward_grid(grid_def, lat_data[col], lon_data[col],
			    &col_data[col], &row_data[col]);
    }

    /*
     *  write a row of column and row numbers
     */
    if (fwrite(col_data, bytes_per_row, 1, fp_col) != 1) {
      fprintf(stderr, "ll2rc: error writing to %s\n", colfile);
      exit(ABORT);
    }
    if (fwrite(row_data, bytes_per_row, 1, fp_row) != 1) {
      fprintf(stderr, "ll2rc: error writing to %s\n", rowfile);
      exit(ABORT);
    }
  }
}
