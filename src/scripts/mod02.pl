#!/usr/local/bin/perl -w
$|=1;
$path_navdir_src = $ENV{PATH_NAVDIR_SRC};
$source_navdir = "$path_navdir_src/scripts";

require("$source_navdir/pfsetup.pl");
require("$source_navdir/error_mail.pl");
require("$source_navdir/date.pl");

my $Usage = "\n
USAGE: mod02.pl dirinout tag listfile gpdfile
                [chanlist [swath_scan_first [swath_scans [keep]]]]
       defaults:    1            0               0          0

  dirinout: directory containing the input and output files.
  tag: string used as a prefix to output files.
  listfile: text file containing a list of MOD02 files to be gridded.
  gpdfile: .gpd file that defines desired output grid.
  chanlist: string specifying channel numbers to be gridded. The default
            is 1, i.e. grid channel 1 only.
  swath_scan_first: the number of the first swath scan to process. The default
                    is 0, i.e. the first scan in the swath.
  swath_scans: the number of scans to process:
                  1km (MOD021KM) files contain 10 rows per scan.
                 500m (MOD02HKM) files contain 20 rows per scan.
                 250m (MOD02QKM) files contain 40 rows per scan.
               A typical 5 minute MOD02 granule contains 203 scans.
               The default is 0, i.e. process all scans in the swath
               following swath_scan_first.
  keep: 0: delete intermediate chan, col, and row files (default).
        1: do not delete intermediate chan, col, and row files.\n\n";

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
my $chanlist = "1";
my $swath_scan_first = 0;
my $swath_scans = 0;
my $keep = 0;

if (@ARGV < 4) {
    print $Usage;
    exit;
}
if (@ARGV <= 8) {
    $dirinout = $ARGV[0];
    $tag = $ARGV[1];
    $listfile = $ARGV[2];
    $gpdfile = $ARGV[3];
    if (@ARGV >= 5) {
	$chanlist = $ARGV[4];
	if (@ARGV >= 6) {
	    $swath_scan_first = $ARGV[5];
	    if (@ARGV >= 7) {
		$swath_scans = $ARGV[6];
		if (@ARGV <= 8) {
		    $keep = $ARGV[7];
		}
	    }
	}
    }
} else {
    print $Usage;
    exit;
}

print_stderr("\n".
	     "$script: MESSAGE:\n".
	     "> dirinout         = $dirinout\n".
	     "> tag              = $tag\n".
	     "> listfile         = $listfile\n".
	     "> gpdfile          = $gpdfile\n".
	     "> chanlist         = $chanlist\n".
	     "> swath_scan_first = $swath_scan_first\n".
	     "> swath_scans      = $swath_scans\n".
	     "> keep             = $keep\n\n");

chdir_or_die($dirinout);

my @list;
open_or_die("LISTFILE", "$listfile");
print_stderr("contents of listfile:\n");
while (<LISTFILE>) {
    push(@list, $_);
    print STDERR "$_";
}
close(LISTFILE);

my $hdf;
my $swath_cols = 0;
my $swath_rows = 0;
my $lat_cat = "cat ";
my $lon_cat = "cat ";
my $chan_count = length($chanlist);
my @chan_cat;
my @chans;
my $i;
for ($i = 0; $i < $chan_count; $i++) {
    $chan_cat[$i] = "cat ";
    $chans[$i] = sprintf("%02d", substr($chanlist, $i, 1));
}
my $swath_rows_per_scan;
foreach $hdf (@list) {
    chomp $hdf;
    my ($filestem) = ($hdf =~ /(.*)\.hdf/);
    for ($i = 0; $i < $chan_count; $i++) {
	my $chan = $chans[$i];
	my $filestem_chan = $filestem . "_ch$chan\_";
	do_or_die("idl_sh.pl extract_chan \"'$hdf'\" $chan");
	my @chan_glob = glob("$filestem_chan*");
	my $chan_file = $chan_glob[0];
	my ($this_swath_cols, $this_swath_rows) =
	    ($chan_file =~ /$filestem_chan(.....)_(.....)/);
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

    my ($resolution) = ($hdf =~ /MOD02(.)/);
    $swath_rows_per_scan = 10;
    my $interp_factor = 1;
    my $hdf_latlon = $hdf;
    if ($resolution eq "1") {
	$hdf_latlon =~ s/1KM/HKM/;
    } else {
	$interp_factor = ($resolution eq "H") ? 2 : 4;
	$swath_rows_per_scan *= $interp_factor;
    }
    do_or_die("idl_sh.pl extract_latlon \"'$hdf_latlon'\" " .
	      "$interp_factor");

    my $filestem_lat = $filestem . "_latf_";
    my @lat_glob = glob("$filestem_lat*");
    my $lat_file = $lat_glob[0];
    my ($this_lat_cols, $this_lat_rows) =
	($lat_file =~ /$filestem_lat(.....)_(.....)/);
    print "$lat_file contains $this_lat_cols cols and " .
	  "$this_lat_rows rows\n";
    if ($this_lat_cols != $swath_cols) {
	diemail("$script: FATAL: " .
		"inconsistent size for $lat_file");
    }
    $lat_cat .= "$lat_file ";

    my $filestem_lon = $filestem . "_lonf_";
    my @lon_glob = glob("$filestem_lon*");
    my $lon_file = $lon_glob[0];
    my ($this_lon_cols, $this_lon_rows) =
	($lon_file =~ /$filestem_lon(.....)_(.....)/);
    print "$lon_file contains $this_lon_cols cols and " .
	  "$this_lon_rows rows\n";
    if ($this_lon_cols != $swath_cols) {
	diemail("$script: FATAL: " .
		"inconsistent size for $lon_file");
    }
    $lon_cat .= "$lon_file ";
}
$swath_rows = sprintf("%05d", $swath_rows);

my @chan_files;
for ($i = 0; $i < $chan_count; $i++) {
    my $chan = $chans[$i];
    my $chan_rm = $chan_cat[$i];
    $chan_rm =~ s/cat/rm -f/;
    $chan_files[$i] = "$tag\_ch$chan\_$swath_cols\_$swath_rows.img";
    do_or_die("$chan_cat[$i] >$chan_files[$i]");
    do_or_die("$chan_rm");
}

my $lat_rm = $lat_cat;
my $lon_rm = $lon_cat;

$lat_rm  =~ s/cat/rm -f/;
$lon_rm  =~ s/cat/rm -f/;

my $lat_file  = "$tag\_latf_$swath_cols\_$swath_rows.img";
my $lon_file  = "$tag\_lonf_$swath_cols\_$swath_rows.img";

do_or_die("$lat_cat  >$lat_file");
do_or_die("$lon_cat  >$lon_file");

do_or_die("$lat_rm");
do_or_die("$lon_rm");

my $col_file  = "$tag\_cols_$swath_cols\_$swath_rows.img";
my $row_file  = "$tag\_rows_$swath_cols\_$swath_rows.img";

do_or_die("ll2cr -v $swath_cols $swath_rows $lat_file $lon_file " .
	  "$gpdfile $col_file $row_file");
if (!$keep) {
    do_or_die("rm -f $lat_file");
    do_or_die("rm -f $lon_file");
}

open_or_die("GPDFILE", "$ENV{PATHMPP}/$gpdfile");
my $line = <GPDFILE>;
$line = <GPDFILE>;
close(GPDFILE);
my ($grid_cols, $grid_rows) = ($line =~ /(\S+)\s+(\S+)/);
if ($swath_scans eq "0") {
    $swath_scans = $swath_rows / $swath_rows_per_scan - $swath_scan_first;
}

my $chan_file_param = "[";
my $grid_file_param = "[";
for ($i = 0; $i < $chan_count; $i++) {
    if ($i > 0) {
	$chan_file_param .= ",";
	$grid_file_param .= ",";
    }
    my $chan_file = $chan_files[$i];
    my $chan = $chans[$i];
    my $grid_file = "$tag\_ch$chan\_grid\_$grid_cols\_$grid_rows.img";
    $chan_file_param .= "\"'$chan_file'\"";
    $grid_file_param .= "\"'$grid_file'\"";
}
$chan_file_param .= "]";
$grid_file_param .= "]";

do_or_die("idl_sh.pl fornav " .
	  "$swath_cols $swath_scans $swath_rows_per_scan " .
	  "\"'$col_file'\" \"'$row_file'\" $chan_file_param " .
	  "$grid_cols $grid_rows $grid_file_param " .
	  "weight_sum_min=0.001 " .
	  "swath_scan_first=$swath_scan_first");
if (!$keep) {
    for ($i = 0; $i < $chan_count; $i++) {
	do_or_die("rm -f $chan_files[$i]");
    }
    do_or_die("rm -f $col_file");
    do_or_die("rm -f $row_file");
}
