# $Id: mod02_usage.pl,v 1.17 2004/10/23 17:39:32 haran Exp haran $

#========================================================================
# mod02_usage.pl - defines mod02.pl usage message
#
# 25-Oct-2000 T. Haran tharan@colorado.edu 303-492-1847
# National Snow & Ice Data Center, University of Colorado, Boulder
#========================================================================

$|=1;

$mod02_usage = "\n
USAGE: mod02.pl dirinout tag listfile gpdfile chanfile
                [ancilfile [latlon_src [ancil_src [keep [rind
       defaults:    none         1          1       0     50
                [fix250 [fixcolfile [fixrowfile
       defaults:    0       none        none
                [tile_cols [tile_rows [tile_overlap]]]]]]]]]]]
                     1          1          60

  dirinout: directory containing the input and output files.
  tag: string used as a prefix to output files.
  listfile: text file containing a list of MOD02, MOD03, MYD02, or MYD03 files
        to be gridded. All files in listfile must be of the same type and
        the same resolution.
  gpdfile: .gpd file that defines desired output grid.
  chanfile: text file containing a list of channels to be gridded, one line
        per channel. If chanfile is \"none\" then no channel data will be
        gridded and ancilfile must not be \"none\". Each line in chanfile
        should consist of up to four fields:
          chan conversion weight_type fill
            where the fields are defined as follows:
              chan - specifies a channel number (1-36).
              conversion - a string that specifies the type of conversion
                that should be performed on the channel. The string must be
                one of the following:
                  raw - raw HDF values (16-bit unsigned integers) (default).
                  corrected - corrected counts (floating-point).
                  radiance - watts per square meter per steradian per
                    micrometer (floating-point).
                  reflectance - (channels 1-19 and 26) reflectance without
                    solar zenith angle correction (floating-point).
                  temperature - (channels 20-25 and 27-36) brightness
                    temperature in kelvin (floating-point).
              weight_type - a string that specifies the type of weighting
                that should be perfomed on the channel. The string must be one
                of the following:
                  avg - use weighted averaging (default).
                  max - use maximum weighting.
              fill - specifies the output fill value. Default is 0.
      NOTE: if first file in listfile is MOD03 or MYD02, then chanfile must be
      \"none\", and both latlon_src and ancil_src are forced to 3.
  ancilfile: text file containing a list of ancillary parameters to be gridded,
        one line per parameter. The default is \"none\" indicating that no
        ancillary parameters should be gridded. Each line in ancilfile should
        consist of up to four fields:
          param conversion weight_type fill delete
            where the fields are defined as follows:
              param - a string that specifies an ancillary parameter to be
                gridded, and must be one of the following 4 character strings:
                  hght - Height
                  seze - SensorZenith
                  seaz - SensorAzimuth
                  rang - Range
                  soze - SolarZenith
                  soaz - SolarAzimuth
                  lmsk - Land/SeaMask (available in MOD03 or MYD03 only)
                  gflg - gflags
              conversion - a string that specifies the type of conversion
                that should be performed on the channel. The string must be
                one of the following:
                  raw - raw HDF values (16-bit signed integers except that
                    Range is 16-bit unsigned integer and Land/SeaMask and
                    gflags are unsigned bytes) (default).
                  scaled - raw values multiplied by a parameter-specific
                    scale factor (floating-point). Note that scale factor
                    for Height, Land/SeaMask, and gflags is 1.
              weight_type - a string that specifies the type of weighting
                that should be perfomed on the channel. The string must be one
                of the following:
                  avg - use weighted averaging (default for all except
                        Land/SeaMask and gflags).
                  max - use maximum weighting (default for Land/SeaMask and
                        gflags).
              fill - specifies the output fill value. Default is 0.
              delete - 0:keep channel after fix250 is complete (default).
                       1:delete channel after fix250 is complete.
  latlon_src: 1: use 5 km lat-lon data from MOD021KM or MYD021KM file
                 (default).
              3: use 1 km lat-lon data from MOD03 or MYD03 file.
              H: use 1 km lat-lon data from MOD02HKM or MYD02HKM file.
              Q: use 1 km lat-lon data from MOD02QKM or MYD02HKM file.
      NOTE: if latlon_src is set to 3, then ancil_src is forced to 3.
  ancil_src: 1: use 5 km ancillary data from MOD021KM or MYD021KM file
                (default).
             3: use 1 km ancillary data from MOD03 or MYD03 file.
      NOTE: if ancil_src is set to 3, then latlon_src is forced to 3.
  keep: 0: delete intermediate chan, lat, lon, col, and row files (default).
        1: do not delete intermediate chan, lat, lon, col, and row files.
  rind: number of pixels to add around intermediate grid to eliminate
        holes in final grid. Default is 50. Must be greater than 0.
      NOTE: If rind is 0, then no check for min/max columns and rows is
      performed. For direct broadcast data which may contain missing lines,
      you should set rind to 0.
  fix250: 0: do not apply de-striping fix for MOD02QKM or MYD02QKM data
             (default).
          1: apply de-striping fix for MOD02QKM or MYD02QKM data and
             keep solar zenith correction.
          2: apply de-striping fix for MOD02QKM or MYD02QKM data and
             undo solar zenith correction.
          3: apply solar zenith correction only for MOD02QKM or MYD02QKM data.
      NOTE: If fix250 is not 0, then param must be set to soze (Solar Zenith)
      and conversion must be set to scaled (decimal degrees) in ancilfile.
  fixcolfile: Specifies the name of an input text file containing a set of
        intercepts and slopes to be used for performing a de-striping fix for
        the columns in a set of MOD02QKM or MYD02QKM data.
  fixrowfile: Specifies the name of an input text file containing a set of
        intercepts and slopes to be used for performing a de-striping fix for
        the rows in a set of MOD02QKM or MYD02QKM data.
      NOTE: If fixcolfile or fixrowfile is \"none\" (the default) then the
      corresponding col or row regressions will be performed and written to an
      output file. This file may then be specified as fixcolfile or fixrowfile
      in a subsequent call to mod02.pl.
      NOTE: If fix250 is not 1 or 2, then fixcolfile and fixrowfile are ignored.
  tile_cols: number of segments to use horizontally in breaking the specified
        grid into tiles. Default is 1. Must be greater than 0.
  tile_rows: number of segments to use vertically in breaking the specified
        grid into tiles. Default is 1. Must be greater than 0.
      NOTE: The total number of tiles produced will be tile_cols x tile_rows.
      If both tile_cols and tile_rows are equal to 1 (the defaults) then no
      tiling will be performed.
  tile_overlap: number of pixels to add around each tile edge that borders
        another tile. Default is 60. Must be greater than 0.\n\n";

# this makes the routine work properly using require in other programs
1
