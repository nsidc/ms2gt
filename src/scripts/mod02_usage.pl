#!/usr/local/bin/perl -w

# $Id: mod02_usage.pl,v 1.2 2001/02/19 23:56:31 haran Exp haran $

#========================================================================
# mod02_usage.pl - defines mod02.pl usage message
#
# 25-Oct-2000 T. Haran tharan@colorado.edu 303-492-1847
# National Snow & Ice Data Center, University of Colorado, Boulder
#========================================================================

$|=1;

$mod02_usage = "\n
USAGE: mod02.pl dirinout tag listfile gpdfile chanfile
                [ancilfile [latlon_src [ancil_src [keep [rind]]]]]
       defaults:   none          1          1       0     50

  dirinout: directory containing the input and output files.
  tag: string used as a prefix to output files.
  listfile: text file containing a list of MOD02 or MOD03 files to be gridded.
        All files in listfile must be of the same type (MOD02 or MOD03) and
        the same resolution.
  gpdfile: .gpd file that defines desired output grid.
  chanfile: text file containing a list of channels to be gridded, one line
        per channel. If chanfile is \"none\" then no channel data will be
        gridded and ancilfile must not be \"none\". Each line in chanfile
        should have the following format:
          chan conversion weight_type fill
            where
              chan - specifies a channel number (1-36).
              conversion is a string that specifies the type of conversion
                that should be performed on the channel. The string must be
                one of the following:
                  raw - raw HDF values (16-bit unsigned integers) (default).
                  corrected - corrected counts (floating-point).
                  radiance - Watts per square meter per steradian per micron
                    (floating-point).
                  reflectance - (channels 1-19 and 26) reflectance without
                    solar zenith angle correction (floating-point).
                  temperature - (channels 20-25 and 27-36) brightness
                    temperatue in Kelvins (floating-point).
              weight_type - is a string that specifies the type of weighting
                that should be perfomed on the channel. The string must be one
                of the following:
                  avg - use weighted averaging (default).
                  max - use maximum weighting.
              fill - specifies the output fill value. Default is 0.
  NOTE: if first file in listfile is MOD03, then chanfile must be \"none\",
        and both latlon_src and ancil_src are forced to 3.
  ancilfile: text file containing a list of ancillary parameters to be gridded,
        one line per parameter. The default is \"none\" indicating that no
        ancillary parameters should be gridded. Each line in ancilfile should
        have the following format:
          param conversion weight_type fill
            where
              param is a string that specifies an ancillary parameter to be
                gridded, and must be one of the following 4 character strings:
                  hght - Height
                  seze - SensorZenith
                  seaz - SensorAzimuth
                  rang - Range
                  soze - SolarZenith
                  soaz - SolarAzimuth
                  lmsk - Land/SeaMask (available in MOD03 only)
                  gflg - gflags
              conversion is a string that specifies the type of conversion
                that should be performed on the channel. The string must be
                one of the following:
                  raw - raw HDF values (16-bit signed integers except that
                    Range is 16-bit unsigned integer and Land/SeaMask and
                    gflags are unsigned bytes) (default).
                  scaled - raw values multiplied by a parameter-specific
                    scale factor (floating-point). Note that scaling factor
                    for Height, Land/SeaMask, and gflags is 1.
              weight_type - is a string that specifies the type of weighting
                that should be perfomed on the channel. The string must be one
                of the following:
                  avg - use weighted averaging (default for all except
                        Land/SeaMask and gflags).
                  max - use maximum weighting (default for Land/SeaMask and
                        gflags).
              fill - specifies the output fill value. Default is 0.
  latlon_src: 1: use 5km latlon from MOD021KM hdf file (default).
              3: use 1km latlon from MOD03 hdf file.
              H: use 1km latlon from MOD02HKM hdf file.
              Q: use 1km latlon form MOD02QKM hdf file.
  NOTE: if latlon_src is set to 3, then ancil_src is forced to 3.
  ancil_src: 1: use 5km ancillary data from MOD021KM hdf file (default).
             3: use 1km ancillary data from MOD03 hdf file.
  NOTE: if ancil_src is set to 3, then latlon_src is forced to 3.
  keep: 0: delete intermediate chan, lat, lon, col, and row files (default).
        1: do not delete intermediate chan, lat, lon, col, and row files.
  rind: number of pixels to add around intermediate grid to eliminate
        holes in final grid. Default is 50.\n\n";

# this makes the routine work properly using require in other programs
1;
