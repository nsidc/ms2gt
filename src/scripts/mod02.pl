#!/usr/local/bin/perl -w
$|=1;
$path_navdir_src = $ENV{PATH_NAVDIR_SRC};
$source_navdir = "$path_navdir_src/scripts";

require("$source_navdir/pfsetup.pl");
require("$source_navdir/error_mail.pl");
require("$source_navdir/date.pl");

my $Usage = "\n
USAGE: modis.pl dirinout tag listfile gpdfile
                [chan [swath_scan_first swath_scans]]
defaults:         1            0             0\n\n";

#The following symbols are defined in pfsetup.pl and were used only once in
#this module. They appear here to suppress warning messages.

my $junk = $script;

# define a global used by do_or_die and invoke_or_die

$script = "MODIS";

# Set command line defaults

my $dirinout;
my $tag;
my $listfile;
my $gpdfile;
my $chan = 1;
my $swath_scan_first = 0;
my $swath_scans = 0;

if (@ARGV < 4) {
    print $Usage;
    exit;
}
if (@ARGV <= 7) {
    $dirinout = $ARGV[0];
    $tag = $ARGV[1];
    $listfile = $ARGV[2];
    $gpdfile = $ARGV[3];
    if (@ARGV >= 5) {
	$chan = sprintf("%02d", $ARGV[4]);
	if (@ARGV >= 7) {
	    $swath_scan_first = $ARGV[5];
	    $swath_scans = $ARGV[6];
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
	     "> chan             = $chan\n".
	     "> swath_scan_first = $swath_scan_first\n".
	     "> swath_scans      = $swath_scans\n\n");

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
my $chan_cat = "cat ";
my $lat_cat = "cat ";
my $lon_cat = "cat ";
my $swath_rows_per_scan;
foreach $hdf (@list) {
    chomp $hdf;
    my ($resolution) = ($hdf =~ /MOD02(.)/);
    $swath_rows_per_scan = 10;
    if ($resolution eq "1") {
	do_or_die("idl_sh.pl extract_chan \"'$hdf'\" $chan");
	my $hdf_500 = $hdf;
	$hdf_500 =~ s/1KM/HKM/;
	do_or_die("idl_sh.pl extract_latlon \"'$hdf_500'\" 1");
    } else {
	my $interp_factor = ($resolution eq "H") ? 2 : 4;
	$swath_rows_per_scan *= $interp_factor;
	do_or_die("idl_sh.pl extract_latlon \"'$hdf'\" " .
		  "$interp_factor channel=$chan");
    }
    my ($filestem) = ($hdf =~ /(.*)\.hdf/);
    my $filestem_chan = $filestem . "_ch$chan\_";
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
    $swath_rows += $this_swath_rows;
    $chan_cat .= "$chan_file ";

    my $filestem_lat = $filestem . "_latf_";
    my @lat_glob = glob("$filestem_lat*");
    my $lat_file = $lat_glob[0];
    my ($this_lat_cols, $this_lat_rows) =
	($lat_file =~ /$filestem_lat(.....)_(.....)/);
    print "$lat_file contains $this_lat_cols cols and " .
	  "$this_lat_rows rows\n";
    if ($this_lat_cols != $this_swath_cols ||
	$this_lat_rows != $this_swath_rows) {
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
    if ($this_lon_cols != $this_swath_cols ||
	$this_lon_rows != $this_swath_rows) {
	diemail("$script: FATAL: " .
		"inconsistent size for $lon_file");
    }
    $lon_cat .= "$lon_file ";
}
$swath_rows = sprintf("%05d", $swath_rows);

my $chan_rm = $chan_cat;
my $lat_rm = $lat_cat;
my $lon_rm = $lon_cat;

$chan_rm =~ s/cat/rm -f/;
$lat_rm  =~ s/cat/rm -f/;
$lon_rm  =~ s/cat/rm -f/;

my $chan_file = "$tag\_ch$chan\_$swath_cols\_$swath_rows.img";
my $lat_file  = "$tag\_latf_$swath_cols\_$swath_rows.img";
my $lon_file  = "$tag\_lonf_$swath_cols\_$swath_rows.img";

do_or_die("$chan_cat >$chan_file");
do_or_die("$lat_cat  >$lat_file");
do_or_die("$lon_cat  >$lon_file");

do_or_die("$chan_rm");
do_or_die("$lat_rm");
do_or_die("$lon_rm");

my $col_file  = "$tag\_cols_$swath_cols\_$swath_rows.img";
my $row_file  = "$tag\_rows_$swath_cols\_$swath_rows.img";

do_or_die("ll2cr -v $swath_cols $swath_rows $lat_file $lon_file " .
	  "$gpdfile $col_file $row_file");

open_or_die("GPDFILE", "$ENV{PATHMPP}/$gpdfile");
my $line = <GPDFILE>;
$line = <GPDFILE>;
close(GPDFILE);
my ($grid_cols, $grid_rows) = ($line =~ /(\S+)\s+(\S+)/);
my $grid_file = "$tag\_grid\_$grid_cols\_$grid_rows.img";
if ($swath_scans eq "0") {
    $swath_scans = $swath_rows / $swath_rows_per_scan;
}

do_or_die("idl_sh.pl fornav " .
	  "$swath_cols $swath_scans $swath_rows_per_scan " .
	  "\"'$col_file'\" \"'$row_file'\" \"'$chan_file'\" " .
	  "$grid_cols $grid_rows " .
	  "\"'$grid_file'\" " .
	  "weight_sum_min=0.001 " .
	  "swath_scan_first=$swath_scan_first");
