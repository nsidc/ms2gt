#!/usr/local/bin/perl -w

$|=1;

$path_ms2gt_src = $ENV{PATH_MS2GT_SRC};
$source_ms2gt = "$path_ms2gt_src/scripts";

require("$source_ms2gt/mod35_l2_usage.pl");
require("$source_ms2gt/setup.pl");
require("$source_ms2gt/error_mail.pl");

$script = "NCDUMPLIST";
$junk = $script;
$junk = $junk;

$Usage = "\n
USAGE: ncdumplist.pl listfile\n";

if (@ARGV != 1) {
    print $Usage;
    exit 1;
}

my $listfile = $ARGV[0];
open_or_die("LISTFILE", "$listfile");
while (<LISTFILE>) {
    my ($file) = /\s*(\S+)/;
    if (defined($file)) {
	do_or_die("ncdump.pl $file");
    }
}
close(LISTFILE);
