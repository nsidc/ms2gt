#!/usr/local/bin/perl -w

# $Id: setup.pl,v 1.1 2001/02/19 23:56:20 haran Exp haran $

#========================================================================
# setup.pl - sets up some global variables for mod02.pl, mod10_l2.pl and
#            mod29.pl 
#
# 25-Oct-2000 T. Haran tharan@colorado.edu 303-492-1847
# National Snow & Ice Data Center, University of Colorado, Boulder
#========================================================================

# The email address of the user running the processing.
#     email will be sent to this user.
# If you want email messages sent to you, then uncomment the next line,
# or set $user_mail_address to a specific address
# (but don't forget the \ in front of the @).

# $user_mail_address="$ENV{USER}\@$ENV{HOST}";

# this makes the routine work properly using require in other programs
1;
