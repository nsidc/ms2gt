#!/usr/local/bin/perl -w
$|=1;
$path_navdir_src = $ENV{PATH_NAVDIR_SRC};
$source_navdir = "$path_navdir_src/scripts";

require("$source_navdir/pfsetup.pl");
require("$source_navdir/error_mail.pl");
require("$source_navdir/date.pl");

my $Usage = "\n
USAGE: mod02.pl dirinout tag listfile gpdfile
                [chanfile [latlon_1km [keep [rind]]]]
       defaults:   none         1       0     50

  dirinout: directory containing the input and output files.
  tag: string used as a prefix to output files.
  listfile: text file containing a list of MOD02 files to be gridded.
  gpdfile: .gpd file that defines desired output grid.
  chanfile: text file containing a list of channels to be gridded, one line
        per channel. The default is \"none\" indicating that only channel
        1 should be gridded as raw 16-bit integers using weighted averaging and
        an output fill value of 0. Each line in chanfile should have the
        following format:
          chan conversion weight_type fill
            where
              chan - specifies a channel number (1-36). Default is 1.
              conversion is a string that specifies the type of conversion
                that should be performed on the channel. The string must be
                one of the following:
                  raw - raw HDF values (16-bit integers) (default).
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
  latlon_1km: 1: for 1km hdf, use 5km latlon from 1km hdf file (default).
              H: for 1km hdf, use 1km latlon from 500m hdf file.
              Q: for 1km hdf, use 1km latlon form 250m hdf file.
    NOTE: if file is not 1km, then latlon_1km is ignored.
  keep: 0: delete intermediate chan, lat, lon, col, and row files (default).
        1: do not delete intermediate chan, lat, lon, col, and row files.
  rind: number of pixels to add around intermediate grid to eliminate
        holes in final grid. Default is 50.\n\n";

#The following symbols are defined in pfsetup.pl and were used only once in
#this module. They appear here to suppress warning messages.

my $junk = $script;

# define a global used by do_or_die and invoke_or_die

$script = "MOD02";

# Set command line defaults

my $dirinout;
my $tag;
my $listfile;
my $gpdfile;
my $chanfile = "none";
my $latlon_1km = "1";
my $keep = 0;
my $rind = 50;

if (@ARGV < 4) {
    print $Usage;
    exit 1;
}
if (@ARGV <= 8) {
    $dirinout = $ARGV[0];
    $tag = $ARGV[1];
    $listfile = $ARGV[2];
    $gpdfile = $ARGV[3];
    if (@ARGV >= 5) {
	$chanfile = $ARGV[4];
	if (@ARGV >= 6) {
	    $latlon_1km = $ARGV[5];
	    if ($latlon_1km ne "1" &&
		$latlon_1km ne "H" &&
		$latlon_1km ne "Q") {
		print "invalid latlon_1km\n$Usage";
		exit 1;
	    }
	    if (@ARGV >= 7) {
		$keep = $ARGV[6];
		if ($keep ne "0" && $keep ne "1") {
		    print "invalid keep\n$Usage";
		    exit 1;
		}
		if (@ARGV >= 8) {
		    $rind = $ARGV[7];
		}
	    }
	}
    }
} else {
    print $Usage;
    exit 1;
}

print_stderr("\n".
	     "$script: MESSAGE:\n".
	     "> dirinout         = $dirinout\n".
	     "> tag              = $tag\n".
	     "> listfile         = $listfile\n".
	     "> gpdfile          = $gpdfile\n".
	     "> chanfile         = $chanfile\n".
	     "> latlon_1km       = $latlon_1km\n".
	     "> keep             = $keep\n".
	     "> rind             = $rind\n");

chdir_or_die($dirinout);

my @list;
open_or_die("LISTFILE", "$listfile");
print_stderr("contents of listfile:\n");
while (<LISTFILE>) {
    push(@list, $_);
    print STDERR "$_";
}
close(LISTFILE);

my @chans;
my @conversions;
my @weight_types;
my @fills;
if ($chanfile eq "none") {
    @chans = (1);
    @conversions = ("raw");
    @weight_types = ("avg");
    @fills = (0);
} else {
    open_or_die("CHANFILE", "$chanfile");
    print_stderr("contents of chanfile:\n");
    while (<CHANFILE>) {
	my ($chan, $conversion, $weight_type, $fill) =
	    /(\d+)\s*(\S*)\s*(\S*)\s*(\S*)/;
	if (!defined($chan)) {
	    diemail("$script: FATAL: invalid channel number\n");
	}
	if (!defined($conversion)) {
	    $conversion = "raw";
	}
	if (!defined($weight_type)) {
	    $weight_type = "avg";
	}
	if (!defined($fill)) {
	    $fill = 0;
	}
	push(@chans, $chan);
	push(@conversions, $conversion);
	push(@weight_types, $weight_type);
	push(@fills, $fill);
	print "$chan $conversion $weight_type $fill\n";
    }
    close(CHANFILE);
}
my $chan_count = scalar(@chans);

my $hdf;
my $swath_cols = 0;
my $swath_rows = 0;
my $latlon_cols = 0;
my $latlon_rows = 0;
my $lat_cat = "cat ";
my $lon_cat = "cat ";
my @chan_cat;
my $i;
for ($i = 0; $i < $chan_count; $i++) {
    $chan_cat[$i] = "cat ";
    $chans[$i] = sprintf("%02d", $chans[$i]);
}
my $swath_rows_per_scan;
my $this_swath_cols;
my $this_swath_rows;
my $this_swath_conv;
my $interp_factor;
my $offset = 0;
my $extra_latlon_col = 0;
my $latlon_rows_per_scan = 10;
foreach $hdf (@list) {
    chomp $hdf;
    my ($filestem) = ($hdf =~ /(.*)\.hdf/);
    my $filestem_lat = $filestem . "_latf_";
    my $filestem_lon = $filestem . "_lonf_";
    do_or_die("rm -f $filestem_lat*");
    do_or_die("rm -f $filestem_lon*");
    for ($i = 0; $i < $chan_count; $i++) {
	my $chan = $chans[$i];
	my $conversion = $conversions[$i];
	my $conv = substr($conversion, 0, 3);
	my $filestem_chan_conv = "$filestem\_ch$chan\_$conv\_";
	do_or_die("rm -f $filestem_chan_conv*");
	my $get_latlon = "";
	if ($i == 0) {
	    my ($resolution) = ($hdf =~ /MOD02(.)/);
	    my $hdf_latlon = $hdf;
	    $swath_rows_per_scan = 10;
	    if ($resolution eq "1") {
		if ($latlon_1km eq "1") {
		    $get_latlon = "/get_latlon";
		    $interp_factor = 5;
		    $offset = 2;
		    $extra_latlon_col = 1;
		    $latlon_rows_per_scan = 2;
		} else {
		    $interp_factor = 1;
		    $hdf_latlon   =~ s/1/$latlon_1km/;
		    $filestem_lat =~ s/1/$latlon_1km/;
		    $filestem_lon =~ s/1/$latlon_1km/;
		    do_or_die("rm -f $filestem_lat*");
		    do_or_die("rm -f $filestem_lon*");
		    do_or_die("idl_sh.pl extract_latlon \"'$hdf_latlon'\"");
		}
	    } else {
		$get_latlon = "/get_latlon";
		$interp_factor = ($resolution eq "H") ? 2 : 4;
		$swath_rows_per_scan *= $interp_factor;
	    }
	}
	do_or_die("idl_sh.pl extract_chan \"'$hdf'\" $chan " .
		  "$get_latlon conversion=\"'$conversion'\"");
	my @chan_glob = glob("$filestem_chan_conv*");
	my $chan_file = $chan_glob[0];
	($this_swath_cols, $this_swath_rows, $this_swath_conv) =
	    ($chan_file =~ /$filestem_chan_conv(.....)_(.....)/);
	print "$chan_file contains $this_swath_cols cols and " .
	    "$this_swath_rows rows\n";
	if ($swath_cols == 0) {
	    $swath_cols = $this_swath_cols;
	}
	if ($this_swath_cols != $swath_cols) {
	    diemail("$script: FATAL: " .
		    "inconsistent number of columns in $chan_file");
	}
	$chan_cat[$i] .= "$chan_file ";
	if ($i == 0) {
	    $swath_rows += $this_swath_rows;
	}
    }

    my @lat_glob = glob("$filestem_lat*");
    my $lat_file = $lat_glob[0];
    my ($this_lat_cols, $this_lat_rows) =
	($lat_file =~ /$filestem_lat(.....)_(.....)/);
    print "$lat_file contains $this_lat_cols cols and " .
	  "$this_lat_rows rows\n";
    if ($interp_factor * $this_lat_cols -
	$extra_latlon_col != $this_swath_cols ||
	$interp_factor * $this_lat_rows != $this_swath_rows) {
	diemail("$script: FATAL: " .
		"inconsistent size for $lat_file");
    }
    $lat_cat .= "$lat_file ";
    $latlon_cols = $this_lat_cols;
    $latlon_rows += $this_lat_rows;

    my @lon_glob = glob("$filestem_lon*");
    my $lon_file = $lon_glob[0];
    my ($this_lon_cols, $this_lon_rows) =
	($lon_file =~ /$filestem_lon(.....)_(.....)/);
    print "$lon_file contains $this_lon_cols cols and " .
	  "$this_lon_rows rows\n";
    if ($interp_factor * $this_lon_cols -
	$extra_latlon_col != $this_swath_cols ||
	$interp_factor * $this_lon_rows != $this_swath_rows) {
	diemail("$script: FATAL: " .
		"inconsistent size for $lon_file");
    }
    $lon_cat .= "$lon_file ";
}
$swath_rows = sprintf("%05d", $swath_rows);
$latlon_cols = sprintf("%05d", $latlon_cols);
$latlon_rows = sprintf("%05d", $latlon_rows);

my @chan_files;
for ($i = 0; $i < $chan_count; $i++) {
    my $chan = $chans[$i];
    my $chan_rm = $chan_cat[$i];
    my $tagext = substr($conversions[$i], 0, 3);
    $chan_rm =~ s/cat/rm -f/;
    $chan_files[$i] = "$tag\_$tagext\_ch$chan\_$swath_cols\_$swath_rows.img";
    do_or_die("$chan_cat[$i] >$chan_files[$i]");
    do_or_die("$chan_rm");
}

my $lat_rm = $lat_cat;
my $lon_rm = $lon_cat;

$lat_rm  =~ s/cat/rm -f/;
$lon_rm  =~ s/cat/rm -f/;

my $lat_file  = "$tag\_latf_$latlon_cols\_$latlon_rows.img";
my $lon_file  = "$tag\_lonf_$latlon_cols\_$latlon_rows.img";

do_or_die("$lat_cat  >$lat_file");
do_or_die("$lon_cat  >$lon_file");

do_or_die("$lat_rm");
do_or_die("$lon_rm");

my $latlon_scans = $latlon_rows / $latlon_rows_per_scan;
my $force = ($interp_factor == 1) ? "-r $rind" : "-f";
my $filestem_cols = $tag . "_cols_";
my $filestem_rows = $tag . "_rows_";
do_or_die("rm -f $filestem_cols*");
do_or_die("rm -f $filestem_rows*");
do_or_die("ll2cr -v $force $latlon_cols $latlon_scans $latlon_rows_per_scan " .
	  "$lat_file $lon_file $gpdfile $tag");
if (!$keep) {
    do_or_die("rm -f $lat_file");
    do_or_die("rm -f $lon_file");
}

my @cols_glob = glob("$filestem_cols*");
my $cols_file = $cols_glob[0];
my ($this_cols_cols, $this_cols_scans,
    $this_cols_scan_first, $this_cols_rows_per_scan) =
    ($cols_file =~ /$filestem_cols(.....)_(.....)_(.....)_(..)/);
print "$cols_file contains $this_cols_cols cols,\n" .
    "   $this_cols_scans scans, $this_cols_scan_first scan_first,\n" .
    "   and $this_cols_rows_per_scan rows_per_scan\n";

my @rows_glob = glob("$filestem_rows*");
my $rows_file = $rows_glob[0];
my ($this_rows_cols, $this_rows_scans,
    $this_rows_scan_first, $this_rows_rows_per_scan) =
    ($rows_file =~ /$filestem_rows(.....)_(.....)_(.....)_(..)/);
print "$rows_file contains $this_rows_cols cols,\n" .
    "   $this_rows_scans scans, $this_rows_scan_first scan_first,\n" .
    "   and $this_rows_rows_per_scan rows_per_scan\n";

if ($this_cols_cols != $this_rows_cols ||
    $this_cols_scans != $this_rows_scans ||
    $this_cols_scan_first != $this_rows_scan_first ||
    $this_cols_rows_per_scan != $this_rows_rows_per_scan) {
    diemail("$script: FATAL: " .
	    "inconsistent sizes for $cols_file and $rows_file");
}
my $cr_cols = $this_cols_cols;
my $cr_scans = $this_cols_scans;
my $cr_scan_first = $this_cols_scan_first;
my $cr_rows_per_scan = $this_cols_rows_per_scan;

open_or_die("GPDFILE", "$ENV{PATHMPP}/$gpdfile");
my $line = <GPDFILE>;
$line = <GPDFILE>;
close(GPDFILE);
my ($grid_cols, $grid_rows) = ($line =~ /(\S+)\s+(\S+)/);
$grid_cols = sprintf("%05d", $grid_cols);
$grid_rows = sprintf("%05d", $grid_rows);

if ($interp_factor > 1) {
    my $col_min = -$rind;
    my $col_max = $grid_cols + $rind - 1;
    my $row_min = -$rind;
    my $row_max = $grid_rows + $rind - 1;

    do_or_die("idl_sh.pl interp_colrow " .
	      "$interp_factor $cr_cols $cr_scans $cr_rows_per_scan " .
	      "\"'$cols_file'\" \"'$rows_file'\" " .
	      "$swath_cols \"'$tag'\" " .
	      "grid_check=[$col_min,$col_max,$row_min,$row_max] " .
	      "col_offset=$offset row_offset=$offset");
    do_or_die("rm -f $cols_file");
    do_or_die("rm -f $rows_file");

    $filestem_cols = $tag . "_cols_";
    @cols_glob = glob("$filestem_cols*");
    $cols_file = $cols_glob[0];
    ($this_cols_cols, $this_cols_scans,
     $this_cols_scan_first, $this_cols_rows_per_scan) =
	 ($cols_file =~ /$filestem_cols(.....)_(.....)_(.....)_(..)/);
    print "$cols_file contains $this_cols_cols cols,\n" .
	  "   $this_cols_scans scans, $this_cols_scan_first scan_first,\n" .
	  "   and $this_cols_rows_per_scan rows_per_scan\n";

    $filestem_rows = $tag . "_rows_";
    @rows_glob = glob("$filestem_rows*");
    $rows_file = $rows_glob[0];
    ($this_rows_cols, $this_rows_scans,
     $this_rows_scan_first, $this_rows_rows_per_scan) =
	 ($cols_file =~ /$filestem_cols(.....)_(.....)_(.....)_(..)/);
    print "$rows_file contains $this_rows_cols cols,\n" .
          "   $this_rows_scans scans, $this_rows_scan_first scan_first,\n" .
          "   and $this_rows_rows_per_scan rows_per_scan\n";

    if ($this_cols_cols != $this_rows_cols ||
	$this_cols_scans != $this_rows_scans ||
	$this_cols_scan_first != $this_rows_scan_first ||
	$this_cols_rows_per_scan != $this_rows_rows_per_scan) {
	diemail("$script: FATAL: " .
		"inconsistent sizes for $cols_file and $rows_file");
    }
    $cr_cols = $this_cols_cols;
    $cr_scans = $this_cols_scans;
    $cr_scan_first = $this_cols_scan_first;
    $cr_rows_per_scan = $this_cols_rows_per_scan;
}

if ($cr_scans == 0) {
    if (!$keep) {
	for ($i = 0; $i < $chan_count; $i++) {
	    do_or_die("rm -f $chan_files[$i]");
	}
	do_or_die("rm -f $cols_file");
	do_or_die("rm -f $rows_file");
    }
    diemail("$script: FATAL: $tag: grid contains no data");
}

if ($swath_cols != $cr_cols) {
    diemail("$script: FATAL: " .
	    "swath_cols: $swath_cols is not equal to cr_cols: $cr_cols");
}
if ($swath_rows_per_scan != $cr_rows_per_scan) {
    diemail("$script: FATAL: " .
	    "swath_rows_per_scan: $swath_rows_per_scan is not equal to cr_rows_per_scan: $cr_rows_per_scan");
}

my $swath_scans = $cr_scans;
my $swath_scan_first = $cr_scan_first;

for ($i = 0; $i < $chan_count; $i++) {
    my $chan_file = $chan_files[$i];
    my $chan = $chans[$i];
    my $tagext = substr($conversions[$i], 0, 3);
    my $m_option;
    if ($weight_types[$i] eq "avg") {
	$m_option = "";
	$tagext .= "a";
    } else {
	$m_option = "-m";
	$tagext .= "m";
    }
    my $grid_file = "$tag\_$tagext\_ch$chan\_$grid_cols\_$grid_rows.img";
    my $t_option;
    my $f_option;
    if ($conversions[$i] eq "raw") {
	$t_option = "-t u2";
	$f_option = "-f 65535";
    } else {
	$t_option = "-t f4";
	$f_option = "-f 65535.0";
    }
    my $fill = $fills[$i];
    my $F_option = "-F $fill";
    do_or_die("fornav 1 -v $t_option $f_option $m_option $F_option " .
	      "-s $swath_scan_first 0 " .
	      "$swath_cols $swath_scans $swath_rows_per_scan " .
	      "$cols_file $rows_file $chan_file " .
	      "$grid_cols $grid_rows $grid_file");
}

if (!$keep) {
    for ($i = 0; $i < $chan_count; $i++) {
	do_or_die("rm -f $chan_files[$i]");
    }
    do_or_die("rm -f $cols_file");
    do_or_die("rm -f $rows_file");
}
