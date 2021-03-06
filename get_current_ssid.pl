#!/usr/bin/perl

use warnings;
use strict;

use Getopt::Std;

our $opt_a = 0;
our $opt_m = 0;

getopts('am');

my $interface = shift;
if (!defined $interface) {
	$interface = "wlan0";
}

if ($opt_a == 0 && $opt_m == 0) {
	$opt_a = 1;
}
if ($opt_a == $opt_m) {
	print STDERR "Error: you have to select only one format\n";
	exit 1;
}

my $res = `sudo iwlist $interface scanning`;
if ($? ne 0) {
    print STDERR "***** Warning ******\nFailed to scan the network.\n" .
	"Check that no network-handling software is running (e.g. network-manager, ifplugd...)\n" .
	    "********************\n";
    exit 1;
}

while ($res =~ /Address: ([0-9A-F:]+).\s+Channel:(\d+).*?ESSID:"(.*?)"/sg) {
	if ($opt_m == 1) {
		print "$1 $2 $3\n";
	} else {
		print "$1:$3\n";
	}
}
