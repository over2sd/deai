#!/usr/bin/perl
use strict;
use warnings;
#use diagnostics;
use utf8;

# deai
my $version = "0.027a";


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

# Main Window
use Prima qw(Application Buttons MsgBox FrameSet);
require PGUI;
require PGK;
require Options;
my $gui = PGK::createMainWin("Dungeon Encounter Action Index",$version);
PGUI::selectCamp($gui);
my $text = $$gui{status};
$text->push("Ready.");
Prima->run();
