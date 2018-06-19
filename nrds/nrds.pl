#!/bin/perl -w
#
# Written by: Eric Stanley (nagios@nagios.org)
# Based on nrds.sh, written by: Scott Wilkerson (nagios@nagios.org)
# Copyright (c) 2010-2012 Nagios Enterprises, LLC.
# 
#
###########################

use Getopt::Long;

require "/usr/local/nrdp/clients/nrds/nrds_common.pl";

my $RELEASE = "Revision 0.1";
my ( $OS, $ARCH, $OS_VER) = get_os_info();

my $nrds_updater = "/usr/local/nrdp/clients/nrds/nrds_updater.pl";

# defaults
my $PATH="/bin:/usr/bin:/usr/sbin";

my $PROGNAME=$0;

# Functions plugin usage
sub print_release {
    print "$RELEASE\n";
}

sub print_usage {
	print <<EOU;

$PROGNAME $RELEASE - Sends passive checks to Nagios NRPD server

Usage: nrds.sh -H hostname [-c /path/to/nrds.cfg]

Usage: $PROGNAME -h display help

EOU
}

sub print_help {
	print_usage();
	print <<EOH;

This script is used to send passive checks in nrds.cfg
to Nagios NRPD server

EOH
	exit( 0);
}

my $configfile = "/usr/local/nrdp/clients/nrds/nrds.cfg";
my $print_help = 0;
my $print_release = 0;
my $hostname = "";
my $fetch_method = "";

my $result = GetOptions(	"config=s"		=> \$configfile,
							"help|?"		=> \$print_help,
							"hostname|H=s"	=> \$hostname,
							"version"		=> \$print_release);

if( $print_help) {
	print_help();
}

if( $print_release) {
	print_release();
	exit( 0);
}

die "Could not find config file at $configfile" unless( -f "$configfile");

if( $hostname eq "") {
	print_usage();
	exit( 1);
}

my $config = process_config( $configfile);

if( ! -f $config->{ "SEND_NRDP"}) {
	print "Could not find SEND_NRDP file at $config->{ 'SEND_NRDP'}\n";
	exit( 1);
}

my $senddata = "";
for( my $x = 0; $x < @{ $config->{ "commands"}}; $x++) {
	my $cmd = (( $config->{ "COMMAND_PREFIX"} eq "") ? "" : 
			$config->{ "COMMAND_PREFIX"} . " ") . 
			$config->{ "commands"}->[ $x]->{ "command"};
	my $output = `$cmd`;
	my $status = $?;
	$status >>= 8 if( $status);
	if( $status > 3) {
		$output = "Error code $status - check plugin";
		$status = 3;
	}
	if( $config->{ "commands"}->[ $x]->{ "service"} eq "__HOST__") {
		$senddata .= "$hostname\t$status\t$output\n";
	}
	else {
		$senddata .= "$hostname\t" . 
				$config->{ "commands"}->[ $x]->{ "service"} . 
				"\t$status\t$output\n";
	}
}

# this just adds a random sleep betweel 1-59 seconds so on large installs
# Apache doesn't get overloaded when the all connect at the same time
sleep int( rand( 59) + 1);

# send the data to the NRDP server
my $send_nrdp = $config->{ 'SEND_NRDP'} . ' -u "' . $config-> { 'URL'} . '" -t "' .
		$config->{ 'TOKEN'} . '"';
open( NRDP, "|PATH=$PATH $send_nrdp") || die "Unable to execute command $send_nrdp";
print NRDP "$senddata";
close( NRDP);

if(( $config->{ "UPDATE_CONFIG"} == 1) && ( $config->{ "CONFIG_NAME"} ne "") && 
		( $config->{ "CONFIG_VERSION"} ne "")) {
	system( "$nrds_updater -H $hostname -c $configfile");
}
