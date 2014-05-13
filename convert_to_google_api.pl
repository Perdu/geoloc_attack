#!/usr/bin/perl

# Converts a list of API obtained with get_ssid_list.pl into a json file for
# Google geoloc API
# Written by Célestin Matte @ citi, Inria, 2014
# arg1 = filename

use strict;
use warnings;
use Getopt::Std;

our $opt_a = 0;
our $opt_m = 0;
our $opt_u = 0;

getopts('amu');
my $filename = shift;

if (!defined $filename) {
        print "Usage: convert_to_google_api.pl [-a|-m|-u] <filename>\n";
	print "-a: format for aircrack-ng (default)\n";
	print "-m: format for mdk3\n";
	print "-u: format with mac addresses only\n";
        exit 1;
}

if ($opt_a == 0 && $opt_m == 0 && $opt_u == 0) {
	$opt_a = 1;
}
if (($opt_a == 1 && $opt_m == 1) ||
	($opt_a == 1 && $opt_u == 1) ||
	    ($opt_u == 1 && $opt_m == 1)) {
	print STDERR "Error: you have to select only one format\n";
	exit 1;
}

open (my $file, '<', $filename) or die "Error opening $filename: $!";
my $first = 1;

print "{\n  'wifiAccessPoints': [\n";

while (<$file>) {
	if ($first == 1) {
		$first = 0;
	} else {
		print ",\n";
	}
	if ($opt_m) {
		if (/^([A-F0-9:]+) (\d+) /) {
			print "  {\n    'macAddress': '$1',\n    'channel': $2\n  }";
		}
	} elsif ($opt_a) {
		if (/^([A-F0-9:]{17}):/) {
			print "  {\n    'macAddress': '$1'\n  }";
		}
	} else {
		if (/^([a-fA-F0-9:]+)/) {
			print "  {\n    'macAddress': '$1'\n  }";
		}
	}
}

print "\n ]\n}";
