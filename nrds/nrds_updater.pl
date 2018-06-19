#!/bin/perl -w
# Written by: Eric Stanley (nagios@nagios.org)
# Based on: nrds_updater.sh, written by: Scott Wilkerson (nagios@nagios.org)
# Copyright (c) 2010-2012 Nagios Enterprises, LLC.
# 
#
###########################

use Getopt::Long;

require "/usr/local/nrdp/clients/nrds/nrds_common.pl";

my $RELEASE = "Revision 0.1";
my ( $OS, $ARCH, $OS_VER) = get_os_info();

# defaults
my $PATH="/bin:/usr/bin:/usr/sbin";

# Functions plugin usage
sub print_release {
	print "$RELEASE\n";
}

sub print_usage {
	print <<EOU;

$0 $RELEASE - NRDS Updater from Nagios NRPD server

Usage: nrds.sh -c /path/to/nrds.cfg

Usage: $0 -h

EOU
}

sub print_help {
	print_usage();
	print <<EOH;

This script is used to update nrds.cfg
from Nagios NRDP server

EOH
    exit 0;
}

sub fetch_plugin {
	my $config = shift;
	my $plugin_name = shift;
	my $plugin_dest = shift;
	my $owner = shift;
	my $group = shift;
	my $fetch_method = shift;
	my $hostname = shift;

	# Create plugin's directory if it doesn't exist
	my $plugindir = `dirname $plugin_dest`;
	chomp $plugindir;
	if( ! -d "$plugindir") {
		system( "PATH=$PATH mkdir -p $plugindir");
		chown( $owner, $group, $plugindir);
	}

	my $postdata = "token=" . $config->{ "TOKEN"} . "&cmd=getplugin&plugin=" . 
			"$plugin_name&os=$OS&arch=$ARCH&os_ver=$OS_VER&hostname=$hostname";
	my $cmd;
	if( $fetch_method eq "curl") {
		$cmd = "PATH=$PATH curl -o $plugin_dest --silent --insecure -d \"$postdata\" \"$config->{ 'URL'}\"";
	}
	else {
		$cmd = "PATH=$PATH wget -qO $plugin_dest --post-data=\"$postdata\" \"$config->{ 'URL'}\"";
	}
	system( $cmd);

	if( -f $plugin_dest) {
		# add permission changes here ?
		chown( $owner, $group, $plugin_dest);
		chmod( 0755, $plugin_dest);
		if( $plugin_name =~ /check_icmp|check_dhcp/) {
			chmod( 4755, $plugin_dest);
		}
	}
	else {
		print "ERROR: plugin $plugin_name could not be retrieved from the NRDP server.  Check NRDS plugin directory.\n";
		return 0;
	}
	return 1;
}

sub update_plugins {
	my $fetch_method = shift;
	my $config = shift;
	my $owner = shift;
	my $group = shift;
	my $hostname = shift;

	my %unique_plugins;

	# Add default plugins if not found
	if( ! -f $config->{ "PLUGIN_DIR"} . "/utils.sh") {
		if( fetch_plugin( $config, "utils.sh", $config->{ 'PLUGIN_DIR'} . "/utils.sh",
				$owner, $group, $fetch_method, $hostname)) {
			$unique_plugins{ "utils.sh"} = 1;
		}
	}
	if( ! -f $config->{ "PLUGIN_DIR"} . "/utils.pm") {
		if( fetch_plugin( $config, "utils.pm", $config->{ 'PLUGIN_DIR'} . "/utils.pm",
				$owner, $group, $fetch_method, $hostname)) {
			$unique_plugins{ "utils.pm"} = 1;
		}
	}
	for( my $i = 0; $i < @{ $config->{ "commands"}}; $i++) {
		my $plugin_path = $config->{ "commands"}->[ $i]->{ "command"};
		$plugin_path =~ s/\s+.*$//;
		my $plugin_name = `basename $plugin_path`;
		chomp $plugin_name;

		# Make sure we aren't downloading the same plugin twice
		if( ! exists( $unique_plugins{ $plugin_name})) {
			if( fetch_plugin( $config, $plugin_name, 
					$config->{ 'PLUGIN_DIR'} . "/$plugin_name", $owner, $group, 
					$fetch_method, $hostname)) {
				$unique_plugins{ $plugin_name} = 1;
			}
		}
	}

	print "Updated " . scalar( keys( %unique_plugins)) . " plugins\n";
}

sub send_data {
	my $fetch_method = shift;
	my $config = shift;
	my $configfile = shift;
	my $pdata = shift;
	my $hostname = shift;

	# Determine the UID and GID for the correct owner and group
	my $owner = ( getpwnam( "nagios"))[ 2];
	my $group = ( getgrnam( "nagios"))[ 2];

	my $rslt;
	if( $fetch_method eq "curl") {
		$rslt = `PATH=$PATH curl --silent --insecure -d "$pdata" $config->{ "URL"}`;
	}
	else {
		$rslt = `PATH=$PATH wget -q -O - --post-data="$pdata" $config->{ "URL"}`;
	}
	my $ret = $?;
	if( $ret != 0) {
		print "$fetch_method exited with error $ret\n";
		exit( $ret);
	}

	$rslt =~ /<status>(.*)<\/status>/;
	my $status = $1;
	$rslt =~ /<message>(.*)<\/message>/;
	my $message = $1;
	die "ERROR: $rslt. Check the server config and version" 
			if( $rslt =~ /NO REQUEST HANDLER/);
	die "ERROR: Could not connect to $config->{ 'URL'}. Check your cfg file." 
			if( $status eq "");
	die "ERROR: NRDP Server said - $message" if( $status == -1);
	if( $status == 1) {
		my $postdata = "token=" . $config->{ "TOKEN"} . "&cmd=getconfig&configname=" .
				$config->{ "CONFIG_NAME"} . 
				"&os=$OS&os_ver=$OS_VER&arch=$ARCH&hostname=$hostname";
		my $save_config;
		if( $fetch_method eq "curl") {
			$save_config = `PATH=$PATH curl -o $configfile --silent --insecure -d "$postdata" "$config->{ 'URL'}"`;
		}
		else {
			$save_config = `PATH=$PATH wget -qO $configfile --post-data="$postdata" "$config->{ 'URL'}"`;
		}
		chown( $owner, $group, $configfile);
		$config = process_config( $configfile);
		print "Updated config to version $config->{ 'CONFIG_VERSION'}\n";

		# check if we need to update plugins
		if( $config->{ "UPDATE_PLUGINS"} == "1") {
			update_plugins( $fetch_method, $config, $owner, $group, $hostname);
		}
	}
}

my $configfile = "/usr/local/nrdp/clients/nrds/nrds.cfg";
my $print_help = 0;
my $print_release = 0;
my $force = 0;
my $fetch_method = "";
my $hostname = "";

my $result = GetOptions(	"config=s"		=> \$configfile,
							"force"			=> \$force,
							"help"			=> \$print_help,
							"hostname|H=s"	=> \$hostname,
							"version"		=> \$print_release);

if( $print_help) {
	print_help();
}

if( $print_release) {
	print_release();
	exit( 0);
}

die "Hostname not specified" unless( $hostname ne "");

die "Could not find config file at $configfile" unless( -f "$configfile");

# Determine method to fetch data
if( `PATH=$PATH which curl` =~ "/curl") {
	$fetch_method = "curl";
}
elsif( `PATH=$PATH which wget` =~ "/wget") {
	$fetch_method = "wget";
}
else {
	die "Either curl or wget are required to run $0";
}

my $config = process_config( $configfile);
die "ERROR: This should not be run on the localhost" 
		if( $config->{ "URL"} =~ /localhost/);

$config->{ "CONFIG_VERSION"} = 0 if( $force);

if(( $config->{ "UPDATE_CONFIG"} == 1) && ( $config->{ "CONFIG_NAME"} ne "") && 
		( $config->{ "CONFIG_VERSION"} ne "")) {
	send_data( $fetch_method, $config, $configfile,
			"token=" . $config->{ "TOKEN"} . "&cmd=updatenrds&configname=" .
			$config->{ "CONFIG_NAME"} . "&version=" . $config->{ "CONFIG_VERSION"} .
			"&os=$OS&os_ver=$OS_VER&arch=$ARCH&hostname=$hostname", $hostname);
}

