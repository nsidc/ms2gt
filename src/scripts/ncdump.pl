#!/usr/local/bin/perl -w
$|=1;
$Usage = "\n
USAGE: ncdump.pl hdf_file\n";

if (@ARGV != 1) {
    print $Usage;
    exit 1;
}

my $hdf_file = $ARGV[0];
system("ncdump -h $hdf_file >$hdf_file.atr");
