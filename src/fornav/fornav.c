/*========================================================================
 * fornav - forward navigation using elliptical weighted average
 *
 * 27-Dec-2000 T.Haran tharan@kryos.colorado.edu 303-492-1847
 * National Snow & Ice Data Center, University of Colorado, Boulder
 *========================================================================*/
static const char fornav_c_rcsid[] = "$Header: /export/data/modis/src/fornav/fornav.c,v 1.4 2001/01/03 22:03:55 haran Exp haran $";

#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include "define.h"
#include "matrix.h"

#define USAGE \
"usage: fornav chan_count\n"\
"              [-v] [-m] [-s swath_scan_first] [-S grid_col_start grid_row_start]\n"\
"       defaults:                   0                     0              0\n"\
"              [-t swath_data_type_1 ... swath_data_type_chan_count]\n"\
"       defaults:          s2                       s2\n"\
"              [-T grid_data_type_1 ... grid_data_type_chan_count]\n"\
"       defaults:  swath_data_type_1    swath_data_type_chan_count]\n"\
"              [-f swath_fill_1 ... swath_fill_chan_count]\n"\
"       defaults:       0                      0\n"\
"              [-F grid_fill_1 ... grid_fill_chan_count]\n"\
"       defaults:  swath_fill_1    swath_fill_chan_count\n"\
"              [-c weight_count] [-w weight_min] [-d weight_distance_max]\n"\
"       defaults:     10000             .01               1.0\n"\
"              [-W weight_sum_min]\n"\
"       defaults:    weight_min\n"\
"              swath_cols swath_scans swath_rows_per_scan\n"\
"              swath_col_file swath_row_file\n"\
"              swath_chan_file_1 ... swath_chan_file_chan_count\n"\
"              grid_cols grid_rows\n"\
"              grid_chan_file_1 ... grid_chan_file_chan_count\n"\
"\n"\
" input : chan_count: number of input and output channel files. This parameter\n"\
"           must precede any specified options.\n"\
"         swath_cols: number of columns in each input swath file.\n"\
"         swath_scans: number of scans in each input swath file.\n"\
"         swath_rows_per_scan: number of swath rows constituting a scan.\n"\
"           Must be at least 2.\n"\
"         swath_col_file: file containing the projected column number of each\n"\
"           swath cell and consisting of swatch_cols x swath_rows of 4 byte\n"\
"           floating-point numbers.\n"\
"         swath_row_file: file containing the projected row number of each\n"\
"           swath cell and consisting of swatch_cols x swath_rows of 4 byte\n"\
"           floating-point numbers.\n"\
"         swath_chan_file_1 ... swath_chan_file_chan_count: swath channel files\n"\
"           1 through chan_count. Each file consists of swath_cols x swath_rows\n"\
"           cells as indicated by swath_data_type (see below).\n"\
"         grid_cols: number of columns in each output grid file.\n"\
"         grid_rows: number of rows in each output grid file.\n"\
"\n"\
" output: grid_chan_file_1 ... grid_chan_file_chan_count: grid channel files\n"\
"           1 through chan_count. Each file consists of grid_cols x grid_rows\n"\
"           cells as indicated by grid_type (see below).\n"\
"\n"\
" option: v: verbose (may be repeated).\n"\
"         s swath_scan_first: the first scan number to process. Default is 0.\n"\
"         S grid_col_start grid_row_start: starting grid column number and row\n"\
"             number to write to each output grid file.\n"\
"         m: maximum weight mode. If -m is not present, a weighted average of\n"\
"             all swath cells that map to a particular grid cell is used.\n"\
"             If -m is present, the swath cell having the maximum weight of all\n"\
"             swath cells that map to a particular grid cell is used. The -m\n"\
"             option should be used for coded data, i.e. snow cover.\n"\
"         t swath_data_type_1 ... swath_data_type_chan_count: specifies the type\n"\
"             of each swath cell for each channel as follows:\n"\
"               u1: unsigned 8-bit integer.\n"\
"               u2: unsigned 16-bit integer.\n"\
"               s2: signed 16-bit integer (default).\n"\
"               u4: unsigned 32-bit integer.\n"\
"               s4: signed 32-bit integer.\n"\
"               f4: 32-bit floating-point.\n"\
"         T grid_data_type_1 ... grid_data_type_chan_count: specifies the type\n"\
"             of each grid cell for each channel as in the -t option. If the\n"\
"             default value is the corresponding swath data type value.\n"\
"         f swath_fill_1 ... swath_fill_chan_count: specifies fill value to use\n"\
"             for detecting any missing cells in each swath file. Missing swath\n"\
"             cells are ignored. The default value is 0.\n"\
"         F grid_fill_1 ... grid_fill_chan_count: specifies fill value to use\n"\
"             for any unmapped cells in each grid file. The default value is the\n"\
"             corresponding swath fill value.\n"\
"         c weight_count: number of elements to create in the gaussian weight\n"\
"             table. Default is 10000. Must be at least 2.\n"\
"         w weight_min: the minimum value to store in the last position of the\n"\
"             weight table. Default is 0.01, which, with a weight_distance_max\n"\
"             of 1.0 produces a weight of 0.01 at a grid cell distance of 1.0.\n"\
"             Must be greater than 0.\n"\
"         d weight_distance_max: distance in grid cell units at which to apply a\n"\
"             weight of weight_min. Default is 1.0. Must be greater than 0.\n"\
"         W weight_sum_min: minimum weight sum value. Cells whose weight sums\n"\
"             are less than weight_sum_min are set to the grid fill value.\n"\
"             Default is weight_sum_min.\n"\
"\n"

#define TYPE_UNDEF  0
#define TYPE_BYTE   1
#define TYPE_UINT2  2
#define TYPE_SINT2  3
#define TYPE_UINT4  4
#define TYPE_SINT4  5
#define TYPE_FLOAT  6

typedef struct {
  char  *name;
  char  *file;
  FILE  *fp;
  char  *open_type_str;
  char  *data_type_str;
  int   data_type;
  int   bytes_per_cell;
  float fill;
  int   cols;
  int   rows;
  int   bytes_per_row;
  void  **buf;
} image;

typedef struct {
  float a;
  float b;
  float c;
  float f;
  float delu;
  float delv;
} ewa_parameters;

typedef struct {
  int   count;
  float min;
  float distance_max;
  float sum_min;
  float alpha;
  float qmax;
  float qfactor;
  float *wtab;
} ewa_weight;

static int verbose;
static int very_verbose;

static void DisplayUsage(void)
{
  error_exit(USAGE);
}

static void DisplayInvalidParameter(char *param)
{
  fprintf(stderr, "fornav: Parameter %s is invalid.\n", param);
  DisplayUsage();
}

static void InitializeImage(image *ip, char *name, char *open_type_str,
			    char *data_type_str, int cols, int rows,
			    int swath_scan_first)
{
  if (very_verbose)
    fprintf(stderr, "Initializing %s\n", name);
  ip->name = strdup(name);
  ip->open_type_str = strdup(open_type_str);
  if (strlen(ip->open_type_str)) {
    if ((ip->fp = fopen(ip->file, ip->open_type_str)) == NULL) {
      fprintf(stderr, "fornav: InitializeImage: error opening %s\n", ip->file);
      perror("fornav");
      exit(ABORT);
    }
  } else
    ip->fp = NULL;
  ip->data_type_str = strdup(data_type_str);
  if (!strcmp(ip->data_type_str, "u1"))
    ip->data_type = TYPE_BYTE;
  else if (!strcmp(ip->data_type_str, "u2"))
    ip->data_type = TYPE_UINT2;
  else if (!strcmp(ip->data_type_str, "s2"))
    ip->data_type = TYPE_SINT2;
  else if (!strcmp(ip->data_type_str, "u4"))
    ip->data_type = TYPE_UINT4;
  else if (!strcmp(ip->data_type_str, "s4"))
    ip->data_type = TYPE_SINT4;
  else if (!strcmp(ip->data_type_str, "f4"))
    ip->data_type = TYPE_FLOAT;
  else
    ip->data_type = TYPE_UNDEF;

  switch (ip->data_type) {
  case TYPE_BYTE:
    ip->bytes_per_cell = 1;
    break;
  case TYPE_UINT2:
  case TYPE_SINT2:
    ip->bytes_per_cell = 2;
    break;
  case TYPE_UINT4:
  case TYPE_SINT4:
  case TYPE_FLOAT:
    ip->bytes_per_cell = 4;
    break;
  case TYPE_UNDEF:
  default:
    error_exit("fornav: InitializeImage: Undefined data type");
    break;
  }

  ip->cols = cols;
  ip->rows = rows;
  ip->bytes_per_row = ip->bytes_per_cell * cols;
  ip->buf = matrix(ip->rows, ip->cols, ip->bytes_per_cell, 0);
  if (ip->buf == NULL) {
    fprintf(stderr, "Error initializing %s\n", name);
    error_exit("fornav: InitializeImage: can't allocate memory for buffer");
  }
  if (!strcmp(ip->open_type_str, "r")) {
    int offset;
    offset = ip->bytes_per_row * ip->rows * swath_scan_first;
    if (very_verbose)
      fprintf(stderr, "seeking to byte %d in %s\n", offset, ip->file);
    if (fseek(ip->fp, offset, 0) != 0) {
      fprintf(stderr,
	      "fornav: InitializeImage: error seeking to byte %d in %s\n",
	      offset, ip->file);
      perror("fornav");
      exit(ABORT);
    }
  }
}

static void DeInitializeImage(image *ip)
{
  if (very_verbose)
    fprintf(stderr, "DeInitializing %s\n", ip->name);
  if (ip->name)
    free(ip->name);
  if (ip->open_type_str)
    free(ip->open_type_str);
  if (ip->data_type_str)
    free(ip->data_type_str);
  if (ip->fp)
    fclose(ip->fp);
  if (ip->buf)
    free(ip->buf);
}

static void ReadImage(image *ip)
{
  if (very_verbose)
    fprintf(stderr, "Reading %s\n", ip->name);
  if (fread(ip->buf[0], ip->bytes_per_row, ip->rows, ip->fp) != ip->rows) {
    fprintf(stderr, "fornav: ReadImage: error reading %s\n", ip->file);
    perror("fornav");
    exit(ABORT);
  }
}

static void InitializeWeight(ewa_weight *ewaw, int weight_count,
			     float weight_min, float weight_distance_max,
			     float weight_sum_min)
{
  float  *wptr;
  int    i;

  if (very_verbose)
    fprintf(stderr, "Initializing weight structure\n");
  ewaw->count        = weight_count;
  ewaw->min          = weight_min;
  ewaw->distance_max = weight_distance_max;
  ewaw->sum_min      = weight_sum_min;
  ewaw->wtab         = calloc(weight_count, sizeof(float));
  if (ewaw->wtab == NULL)
    error_exit("fornav: InitializeWeight: can't allocate memory for wtab");
  if (weight_count < 2)
    error_exit("fornav: InitializeWeight: weight_count must be at least 2");
  if (weight_min <= 0.0)
    error_exit("fornav: InitializeWeight: weight_min must be greater than 0");
  if (weight_distance_max <= 0.0)
    error_exit("fornav: InitializeWeight: weight_distance_max must be greater than 0");
  ewaw->qmax = ewaw->distance_max * ewaw->distance_max;
  ewaw->alpha = -log(ewaw->min) / ewaw->qmax;
  wptr = ewaw->wtab;
  for (i = 0; i < weight_count; i++)
    *wptr++ = exp(-ewaw->alpha * ewaw->qmax * (float)i / (ewaw->count - 1));

  /*
   *  Use i = (int)(q * ewaw->qfactor) to get element number i of wtab
   *  corresponding to q.
   *  Then for 0 < q < ewaw->qmax
   *    we have:
   *      0   < i              <= ewaw->count - 1
   *      1.0 > ewaw->wtab[i]  >= ewaw->min
   */

  ewaw->qfactor = ewaw->count / ewaw->qmax;
  if (very_verbose) {
    fprintf(stderr, "alpha = %f  qmax = %f\n",
	    ewaw->alpha, ewaw->qmax);
    fprintf(stderr, "wtab[%d] = %f\n",
	    0, ewaw->wtab[0]);
    fprintf(stderr, "wtab[%d] = %f\n",
	    ewaw->count - 1, ewaw->wtab[ewaw->count - 1]);
  }
}

static void DeInitializeWeight(ewa_weight *ewaw)
{
  if (very_verbose)
    fprintf(stderr, "DeInitializing weight structure");
  if (ewaw->wtab)
    free(ewaw->wtab);
}

main (int argc, char *argv[])
{
  char  *option;
  int   chan_count;
  int   swath_scan_first;
  int   grid_col_start;
  int   grid_row_start;
  bool  maximum_weight_mode;
  bool  got_grid_data_type;
  bool  got_grid_fill;
  int   weight_count;
  float weight_min;
  float weight_distance_max;
  float weight_sum_min;
  bool  got_weight_sum_min;
  int   swath_cols;
  int   swath_scans;
  int   swath_rows_per_scan;
  int   grid_cols;
  int   grid_rows;

  image  *swath_col_image;
  image  *swath_row_image;
  image  *swath_chan_image;
  image  *grid_chan_io_image;
  image  *grid_chan_image;
  image  *grid_weight_image;
  image  *ip;

  ewa_parameters *ewap;
  ewa_weight     ewaw;

  int   i;
  int   swath_scan_last;
  int   scan;
  
  /*
   *	set defaults
   */
  verbose                = FALSE;
  very_verbose           = FALSE;
  swath_scan_first       = 0;
  grid_col_start         = 0;
  grid_row_start         = 0;
  maximum_weight_mode    = FALSE;
  got_grid_data_type     = FALSE;
  got_grid_fill          = FALSE;
  weight_count           = 10000;
  weight_min             = 0.01;
  weight_distance_max    = 1.0;
  got_weight_sum_min     = FALSE;

  /*
   *  Get channel count and use it to allocate images and set default values
   */

  ++argv; --argc;
  if (argc <= 0)
    DisplayUsage();
  if (sscanf(*argv, "%d", &chan_count) != 1)
    DisplayInvalidParameter("chan_count");

  if ((swath_col_image = (image *)malloc(sizeof(image))) == NULL)
    error_exit("fornav: can't allocate swath_col_image\n");
  if ((swath_row_image = (image *)malloc(sizeof(image))) == NULL)
    error_exit("fornav: can't allocate swath_row_image\n");
  if ((swath_chan_image = (image *)calloc(chan_count, sizeof(image))) == NULL)
    error_exit("fornav: can't allocate swath_chan_image\n");
  if ((grid_chan_io_image = (image *)calloc(chan_count, sizeof(image))) == NULL)
    error_exit("fornav: can't allocate grid_chan_io_image\n");
  if ((grid_chan_image = (image *)calloc(chan_count, sizeof(image))) == NULL)
    error_exit("fornav: can't allocate grid_chan_image\n");
  if ((grid_weight_image = (image *)malloc(sizeof(image))) == NULL)
    error_exit("fornav: can't allocate grid_weight_image\n"); 

  for (i = 0; i < chan_count; i++) {
    ip = &swath_chan_image[i];
    ip->data_type_str = "s2";
    ip->fill = 0.0;

    ip = &grid_chan_io_image[i];
    ip->data_type_str = "s2";
    ip->fill = 0.0;
  }

  /* 
   *	Get command line options
   */
  while (--argc > 0 && (*++argv)[0] == '-') {
    for (option = argv[0]+1; *option != '\0'; option++) {
      switch (*option) {
      case 'v':
	if (verbose)
	  very_verbose = TRUE;
	verbose = TRUE;
	break;
      case 'm':
	maximum_weight_mode = TRUE;
	break;
      case 's':
	++argv; --argc;
	if (argc <= 0)	  
	  DisplayInvalidParameter("swath_scan_first");
	if (sscanf(*argv, "%d", &swath_scan_first) != 1)
	  DisplayInvalidParameter("swath_scan_first");
	break;
      case 'S':
	++argv; --argc;
	if (argc <= 0)
	  DisplayInvalidParameter("grid_col_start");
	if (sscanf(*argv, "%d", &grid_col_start) != 1)
	  DisplayInvalidParameter("grid_col_start");
	++argv; --argc;
	if (argc <= 0)
	  DisplayInvalidParameter("grid_row_start");
	if (sscanf(*argv, "%d", &grid_row_start) != 1)
	  DisplayInvalidParameter("grid_row_start");
	break;
      case 't':
	for (i = 0; i < chan_count; i++) {
	  ++argv; --argc;
	  if (argc <= 0)
	    DisplayInvalidParameter("swath_data_type");
	  if (strcmp(*argv, "u1") &&
	      strcmp(*argv, "u2") &&
	      strcmp(*argv, "s2") &&
	      strcmp(*argv, "u4") &&
	      strcmp(*argv, "s4") &&
	      strcmp(*argv, "f4"))
	    DisplayInvalidParameter("swath_data_type");
	  swath_chan_image[i].data_type_str = *argv;
	}
	break;
      case 'T':
	got_grid_data_type = TRUE;
	for (i = 0; i < chan_count; i++) {
	  ++argv; --argc;
	  if (argc <= 0)
	    DisplayInvalidParameter("grid_data_type");
	  if (strcmp(*argv, "u1") &&
	      strcmp(*argv, "u2") &&
	      strcmp(*argv, "s2") &&
	      strcmp(*argv, "u4") &&
	      strcmp(*argv, "s4") &&
	      strcmp(*argv, "f4"))
	    DisplayInvalidParameter("grid_data_type");
	  grid_chan_io_image[i].data_type_str = *argv;
	}
	break;
      case 'f':
	for (i = 0; i < chan_count; i++) {
	  ++argv; --argc;
	  if (argc <= 0)
	    DisplayInvalidParameter("swath_fill");
	  if (sscanf(*argv, "%f", &swath_chan_image[i].fill) != 1)
	    DisplayInvalidParameter("swath_fill");
	}
	break;
      case 'F':
	got_grid_fill = TRUE;
	for (i = 0; i < chan_count; i++) {
	  ++argv; --argc;
	  if (argc <= 0)
	    DisplayInvalidParameter("grid_fill");
	  if (sscanf(*argv, "%f", &grid_chan_io_image[i].fill) != 1)
	    DisplayInvalidParameter("grid_fill");
	}
	break;
      case 'c':
	++argv; --argc;
	if (argc <= 0)	  
	  DisplayInvalidParameter("weight_count");
	if (sscanf(*argv, "%d", &weight_count) != 1)
	  DisplayInvalidParameter("weight_count");
	break;
      case 'w':
	++argv; --argc;
	if (argc <= 0)	  
	  DisplayInvalidParameter("weight_min");
	if (sscanf(*argv, "%f", &weight_min) != 1)
	  DisplayInvalidParameter("weight_min");
	break;
      case 'd':
	++argv; --argc;
	if (argc <= 0)	  
	  DisplayInvalidParameter("weight_distance_max");
	if (sscanf(*argv, "%f", &weight_distance_max) != 1)
	  DisplayInvalidParameter("weight_distance_max");
	break;
      case 'W':
	got_weight_sum_min = TRUE;
	++argv; --argc;
	if (argc <= 0)	  
	  DisplayInvalidParameter("weight_sum_min");
	if (sscanf(*argv, "%f", &weight_sum_min) != 1)
	  DisplayInvalidParameter("weight_sum_min");
	break;
      default:
	fprintf(stderr,"invalid option %c\n", *option);
	DisplayUsage();
      }
    }
  }
  if (!got_grid_data_type)
    for (i = 0; i < chan_count; i++)
      grid_chan_io_image[i].data_type_str = swath_chan_image[i].data_type_str;
  if (!got_grid_fill)
    for (i = 0; i < chan_count; i++)
      grid_chan_io_image[i].fill = swath_chan_image[i].fill;
  if (!got_weight_sum_min)
    weight_sum_min = weight_min;

  /*
   *	Get command line parameters.
   */
  if (very_verbose)
    fprintf(stderr, "fornav_c_rcsid: %s\n", fornav_c_rcsid);
  if (argc != 7 + 2 * chan_count)
    DisplayUsage();
  if (sscanf(*argv++, "%d", &swath_cols) != 1)
    DisplayInvalidParameter("swath_cols");
  if (sscanf(*argv++, "%d", &swath_scans) != 1)
    DisplayInvalidParameter("swath_scans");
  if (sscanf(*argv++, "%d", &swath_rows_per_scan) != 1)
    DisplayInvalidParameter("swath_rows_per_scan");
  swath_col_image->file = *argv++;
  swath_row_image->file = *argv++;
  for (i = 0; i < chan_count; i++)
    swath_chan_image[i].file = *argv++;
  if (sscanf(*argv++, "%d", &grid_cols) != 1)
    DisplayInvalidParameter("grid_cols");
  if (sscanf(*argv++, "%d", &grid_rows) != 1)
    DisplayInvalidParameter("grid_rows");
  for (i = 0; i < chan_count; i++)
    grid_chan_io_image[i].file = *argv++;

  if (verbose) {
    fprintf(stderr, "fornav:\n");
    fprintf(stderr, "  chan_count          = %d\n", chan_count);
    fprintf(stderr, "  swath_cols          = %d\n", swath_cols);
    fprintf(stderr, "  swath_scans         = %d\n", swath_scans);
    fprintf(stderr, "  swath_rows_per_scan = %d\n", swath_rows_per_scan);
    fprintf(stderr, "  swath_col_file      = %s\n", swath_col_image->file);
    fprintf(stderr, "  swath_row_file      = %s\n", swath_row_image->file);
    for (i = 0; i < chan_count; i++)
      fprintf(stderr, "  swath_chan_file[%d]  = %s\n", i,
	      swath_chan_image[i].file);
    fprintf(stderr, "  grid_cols           = %d\n", grid_cols);
    fprintf(stderr, "  grid_rows           = %d\n", grid_rows);
    for (i = 0; i < chan_count; i++)
      fprintf(stderr, "  grid_chan_file[%d]   = %s\n", i,
	      grid_chan_io_image[i].file);
    fprintf(stderr, "\n");
    fprintf(stderr, "  maximum_weight_mode = %d\n", maximum_weight_mode);
    fprintf(stderr, "  swath_scan_first    = %d\n", swath_scan_first);
    fprintf(stderr, "  grid_col_start      = %d\n", grid_col_start);
    fprintf(stderr, "  grid_row_start      = %d\n", grid_row_start);
    for (i = 0; i < chan_count; i++)
      fprintf(stderr, "  swath_data_type[%d]  = %s\n", i,
	      swath_chan_image[i].data_type_str);
    for (i = 0; i < chan_count; i++)
      fprintf(stderr, "  grid_data_type[%d]   = %s\n", i,
	      grid_chan_io_image[i].data_type_str);
    for (i = 0; i < chan_count; i++)
      fprintf(stderr, "  swath_fill[%d]       = %f\n", i,
	      swath_chan_image[i].fill);
    for (i = 0; i < chan_count; i++)
      fprintf(stderr, "  grid_fill[%d]        = %f\n", i,
	      grid_chan_io_image[i].fill);
    fprintf(stderr, "\n");
    fprintf(stderr, "  weight_count        = %d\n", weight_count);
    fprintf(stderr, "  weight_min          = %f\n", weight_min);
    fprintf(stderr, "  weight_distance_max = %f\n", weight_distance_max);
    fprintf(stderr, "  weight_sum_min      = %f\n", weight_sum_min);
    fprintf(stderr, "\n");
  }

  /*
   *  Initialize images
   */
  if (swath_rows_per_scan < 2)
    error_exit("fornav: swath_rows_per_scan must be at least 2");
  InitializeImage(swath_col_image, "swath_col_image", "r", "f4",
		  swath_cols, swath_rows_per_scan, swath_scan_first);

  InitializeImage(swath_row_image, "swath_row_image", "r", "f4",
		  swath_cols, swath_rows_per_scan, swath_scan_first);
  for (i = 0; i < chan_count; i++) {
    char name[100];
    sprintf(name, "swath_chan_image %d", i); 
    InitializeImage(&swath_chan_image[i], name, "r",
		    swath_chan_image[i].data_type_str,
		    swath_cols, swath_rows_per_scan, swath_scan_first);
    sprintf(name, "grid_chan_io_image %d", i); 
    InitializeImage(&grid_chan_io_image[i], name, "w",
		    grid_chan_io_image[i].data_type_str,
		    grid_cols, 1, 0);
    sprintf(name, "grid_chan_image %d", i); 
    InitializeImage(&grid_chan_image[i], name, "", "f4",
		    grid_cols, grid_rows, 0);
  }

  InitializeImage(grid_weight_image, "grid_weight_image", "", "f4",
		  grid_cols, grid_rows, 0);

  /*
   *  Allocate an array of ewa parameters, one element per swath column
   */
  ewap = (ewa_parameters *)calloc(swath_cols, sizeof(ewa_parameters));
  if (ewap == NULL)
    error_exit("fornav: can't allocate ewa parameters\n");

  /*
   *  Initialize the ewa weight structure
   */
  InitializeWeight(&ewaw, weight_count, weight_min, weight_distance_max,
		   weight_sum_min);

  /*
   *  Process each scan
   */
  swath_scan_last = swath_scan_first + swath_scans - 1;
  for (scan = swath_scan_first; scan <= swath_scan_last; scan++) {
    if (very_verbose)
      fprintf(stderr, "Processing scan %d\n", scan);

    /*
     *  Read a scan from each swath file
     */
    ReadImage(swath_col_image);
    ReadImage(swath_row_image);
    for (i = 0; i < chan_count; i++)
      ReadImage(&swath_chan_image[i]);

  } /* for (scan = swath_scan_first; scan <= swath_scan_last; scan++) */

  /*
   *  De-Initialize images
   */
  DeInitializeImage(swath_col_image);
  DeInitializeImage(swath_row_image);
  for (i = 0; i < chan_count; i++) {
    DeInitializeImage(&swath_chan_image[i]);
    DeInitializeImage(&grid_chan_io_image[i]);
    DeInitializeImage(&grid_chan_image[i]);
  }
  DeInitializeImage(grid_weight_image);

  /*
   *  De-Initialize the weight structure
   */
  DeInitializeWeight(&ewaw);

  /*
   *  Free allocated memory
   */
  free(swath_col_image);
  free(swath_row_image);
  free(swath_chan_image);
  free(grid_chan_io_image);
  free(grid_chan_image);
  free(grid_weight_image);
  free(ewap);
}
