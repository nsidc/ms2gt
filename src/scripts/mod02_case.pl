#!/usr/local/bin/perl -w
$|=1;

sub mod02_case {
    my ($ancil_src, $latlon_src, $filestem) = @_;
    my $case;

    my $prefix = substr($filestem, 0, 5);
    if ($prefix eq "MOD03") {
	$filestem = substr($filestem, 0, 19);
	$case = 9;
	$latlon_src = 3;
	$ancil_src = 3;
    } else {
	$prefix = substr($filestem, 0, 8);
	$filestem = substr($filestem, 0, 22);
	if ($ancil_src eq "1" && $latlon_src eq "3") {
	    $ancil_src = "3";
	}
	if ($ancil_src eq "3") {
	    $latlon_src = "3";
	    if ($prefix eq "MOD021KM") {
		$case = 6;
	    } elsif ($prefix eq "MOD02HKM") {
		$case = 7;
	    } else {
		$case = 8;
	    }
	} else {
	    if ($latlon_src eq "1") {
		if ($prefix eq "MOD021KM") {
		    $case = 1;
		} elsif ($prefix eq "MOD02HKM") {
		    $case = 3;
		    $latlon_src = "H";
		} else {
		    $case = 5;
		    $latlon_src = "Q";
		}
	    } elsif ($latlon_src eq "H") {
		if ($prefix eq "MOD021KM") {
		    $case = 2;
		} elsif ($prefix eq "MOD02HKM") {
		    $case = 3;
		} else {
		    $case = 5;
		    $latlon_src = "Q";
		}
	    } else {
		if ($prefix eq "MOD021KM") {
		    $case = 4;
		} elsif ($prefix eq "MOD02HKM") {
		    $case = 3;
		    $latlon_src = "H";
		} else {
		    $case = 5;
		}
	    }
	}
    }
    return($ancil_src, $latlon_src, $filestem, $prefix, $case);
}

1
