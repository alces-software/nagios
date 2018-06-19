# Written by: Eric Stanley (nagios@nagios.org)
# Based on: nrds_updater.sh, written by: Scott Wilkerson (nagios@nagios.org)
# Copyright (c) 2010-2012 Nagios Enterprises, LLC.
# 
#
###########################

sub get_os_info {
	#this needs some help to better detect everything
	$os = `uname -s`;
	chomp $os;
	$arch = `uname -p`;
	chomp $arch;
	$os_ver = `uname -r`;
	chomp $os_ver;

	return ( $os, $arch, $os_ver);
}

sub process_config {
	my $configfile = shift;

	my %config;
	my @commands;

	# Process the config
	my @valid_fields = ( "URL", "TOKEN", "TMPDIR", "SEND_NRDP", "COMMAND_PREFIX", 
			"CONFIG_NAME", "CONFIG_VERSION", "CONFIG_NAME", "CONFIG_OS", 
			"UPDATE_CONFIG", "UPDATE_PLUGINS", "PLUGIN_DIR", "HOSTNAME", "LOG_FILE", "LOG_NAME");
	my %valid_fields;
	for( my $x = 0; $x < @valid_fields; $x++) {
		$valid_fields{ $valid_fields[ $x]} = 1;
	}

	# Read the configuration file
	open( CONFIG, "$configfile") || die "Unable to open $configfile for reading.";
	while( <CONFIG>) {
		chomp;
		next if( /^\s*$/); # Skip blank lines
		next if( /^#/); # Skip comment lines

		#grab all the commands and put in arrays
		if( /^command\[(.+)\]\s*=\s*(.*)$/) {
			push( @commands, { "service" => $1, "command" => $2});
		}
		# not a command lets process the rest of the config
		# first make sure it is part of valid_fields
		elsif( /^([^=]+)\s*=\s*"?([^"]*)"?\s*$/) {
			my( $key, $value) = ( $1, $2);
			die "Invalid field: $key" unless( exists( $valid_fields{ $key}));
			$config{ $key} = $value;
		}
		else {
			die "Unparsable configuration line: $_";
		}
	}
	$config{ "commands"} = \@commands;

	return \%config;
}

1;
