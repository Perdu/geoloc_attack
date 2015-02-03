#!/usr/bin/perl

# Get list of ssid and bssid from some coordinates, from wigles
# arg1 = latitude
# arg2 = longitude
# todo: displaying only unique ssid should be an option

use strict;
use warnings;

use WWW::Mechanize;
use URI::Escape;
use Getopt::Std;
use JSON::Parse 'parse_json';

my $url = 'https://wigle.net/api/v1/jsonSearch';
my $mech = WWW::Mechanize->new;
my $page;
my $json;
my @results;
my %h;
my $pagestart = 0;
my $end = 0;
my $cookie;
my $default_cookie = 'auth=citi_test3%3A905318744%3A1394028288%3AJ9diNCAcDNc6yyT3MkxSZQ';

my $r = '<td>.*?</td>';
my $precision = 0.002;

our $opt_u = 0;
our $opt_h = 0;
our $opt_a = 0;
our $opt_m = 0;
our $opt_c = "";
our $opt_p = 0;

getopts('uhamc:p:');
my $lat = shift;
my $long = shift;

if (!defined $lat || !defined $long || $opt_h == 1) {
	print "Usage: get_ssid_list.pl [-c <cookie>] [-u] [-h] [-a|-m] lat long\n";
	print "-c <cookie>: use a different authentication cookie for Wigle\n";
	print "-h: prints this help message and exit\n";
	print "-u: display each ssid only once (otherwise, new ssids are generated)\n";
	print "-a: format for aircrack-ng (default)\n";
	print "-m: format for mdk3\n";
	print "-p: change precision of the search (default: $precision)\n";
	exit 1;
}

if ($opt_a == 0 && $opt_m == 0) {
	$opt_a = 1;
}
if ($opt_a == $opt_m) {
	print STDERR "Error: you have to select only one format\n";
	exit 1;
}

if ($opt_c eq "") {
	$cookie = $default_cookie;
} else {
       $cookie = $opt_c;
}

if ($opt_p != 0) {
	$precision = $opt_p;
}

$mech->add_header('Cookie' => $cookie);

$mech->post($url, [
	'latrange1' => $lat,
	'latrange2' => $lat + $precision,
	'longrange1' => $long,
	'longrange2' => $long + $precision,
	'variance' => '0.010',
	'netid' => '',
	'ssid' => '',
	'lastupdt' => '',
	'addresscode' => '',
	'statecode' => '',
	'zipcode' => '',
	'Query' => 'Query'
]);

$page = $mech->content();

if ($page =~ /too many queries/) {
	print STDERR "Too many queries\nUse another Wigle cookie or another IP.\n";
	exit -1;
}

$json = parse_json ($page);
# @{} returns the array, otherwise we only get the reference and we
# can't loop through it.
@results = @{$json->{'results'}};

foreach my $AP (@results) {
	my $bssid = $AP->{'netid'};
	# Fix Wigle's sometime broken format "AA:BB:CCDD:EE:FF"
	$bssid =~ s/([A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2})([A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2})/$1:$2/;
	my $ssid = $AP->{'ssid'};
	my $channel = $AP->{'channel'};
	if (!exists($h{$ssid})) {
		$h{$ssid}++;
		if ($opt_m == 1) {
			print "$bssid $channel $ssid\n";
		} else {
			print "$bssid:$ssid\n";
		}
	} elsif ($opt_u == 0) {
		# This SSID already exists: generate a new one
		my $count = 0;
		my $new_name = $ssid . $count;
		while(exists $h{$new_name}) {
			$count++;
			$new_name = $ssid . $count;
		}
		if (length($new_name) > 32) {
			print STDERR "Could not generate a short " .
			    "enough name for $ssid\n";
		} else {
			$h{$new_name}++;
			if ($opt_m == 1) {
				print "$bssid $channel $new_name\n";
			} else {
				print "$bssid:$new_name\n";
			}
		}
	}
}

if (scalar(keys %h) == 0) {
	print STDERR "Error: Got 0 AP\n";
	print STDERR "This location has no AP at this precision: $precision\n";
	exit 1;
}

exit 0;
