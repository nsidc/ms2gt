#!/usr/local/bin/perl -w

# $Id: pfsetup.pl,v 1.170 2000/12/20 17:55:04 haran Exp $

#========================================================================
# setup.pl - sets up some global variables for mod02.pl, mod10_l2.pl and
#            mod29.pl 
#
# 25-Oct-2000 T. Haran tharan@colorado.edu 303-492-1847
# National Snow & Ice Data Center, University of Colorado, Boulder
#========================================================================

# The email address of the user running the processing
#     mail will be sent to this user

if (!defined($ENV{HOST})) {
    $host = "snow";
} else {
    $host = $ENV{HOST};
    $host =~ s/.colorado.edu//;
}

if ($host eq "snow") {
    $user_mail_address = "haran\@barrow.colorado.edu";
} else {
    $user_mail_address="$ENV{USER}\@$ENV{HOST}";
}

# this makes the routine work properly using require in other programs
1;
