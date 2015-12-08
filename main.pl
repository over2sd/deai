#!/usr/bin/perl
use strict;
use warnings;
#use diagnostics;
use utf8;

# deai
my $version = "0.01a";


my $count = shift || 1;
sub getCount { return $count; }

$|++; # Immediate STDOUT, maybe?

use Getopt::Long;
my $conffilename = 'config.ini';
my $debug = 0; # verblevel
sub howVerbose { return $debug; }

GetOptions(
	'conf|c=s' => \$conffilename,
	'verbose|v=i' => \$debug,
);

use lib "./modules/";
# print "Loading modules...";

require Sui; # DEAI Data stores
require Common;
require FIO;
require deaiXML;
require Entities;

FIO::loadConf($conffilename);
FIO::config('Debug','v',howVerbose());
# other defaults:
foreach (Sui::getDefaults()) {
	FIO::config(@$_) unless defined FIO::config($$_[0],$$_[1]);
}

# splash pane
use Prima qw(Application Buttons MsgBox FrameSet);
require PGK;
my $splash = Prima::MainWindow->new(
		text => "Loading...",
		size => [600,200],
	);
my $output = $splash->insert(StatBox => name => "status");

# load party
my ($party,$error) = deaiXML::fromXML(FIO::config('Main','partyfn'),$output);
(defined $party or die $error); # TODO replace die with a dialog for entering a new party member.
my @partymembers = ();
foreach my $p (@$party) {
	my $m = PC->new(%$p);
	push(@partymembers,$m);
}
use Data::Dumper;
print Dumper @partymembers;
# prepare tabs
# 	encounter enitities tab
#	encounter managing tab
# display windows


Prima->run();
