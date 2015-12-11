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

# Main Window
use Prima qw(Application Buttons MsgBox FrameSet);
require PGUI;
require PGK;
require Options;
my $gui = PGK::createMainWin("Dungeon Encounter Action Index",$version);
my $win = $$gui{mainWin};
my $output = $win->insert(StatBox => name => "status");

# load party
my ($party,$error) = deaiXML::fromXML(FIO::config('Main','partyfn'),$output);
(defined $party or die $error); # TODO replace die with a dialog for entering a new party member.
my @partymembers = ();
foreach my $p (@$party) {
	my $m = PC->new(%$p);
	push(@partymembers,$m);
}
Sui::storeData('party',\@partymembers);
$output->destroy();
# prepare tabs
	#build a list of tabs (from module lister) that we'll be using
my @tabs = qw( Party Opponents Time ); # TODO: generate dynamically
my $pager = $win->insert( Pager => name => 'Pages', pack => { fill => 'both', expand => 1}, );
$pager->build(@tabs);
my $i = 1;
my $color = Common::getColors(17,1);
#	party tab
my $partypage = $pager->insert_to_page(0,VBox =>
		backColor => ColorRow::stringToColor($color),
		pack => { fill => 'both', },
	);
$partypage->insert( SpeedButton => text => "Add Party Member", pack => {fill => 'none', expand => 0} );
# TODO: add Player function
foreach (@partymembers) {
	$color = Common::getColors(($i++ % 2 ? 0 : 14),1);
	$_->makeRow($partypage,$color);
}
$color = Common::getColors($i++,1);
# 	encounter enitities tab
my $opponentpage = $pager->insert_to_page(1,VBox =>
		backColor => ColorRow::stringToColor($color),
		pack => { fill => 'both', },
	);
my $filebox = $opponentpage->insert( VBox => name => 'filechoices' );
my $odir = (FIO::config('Main','oppdir') or "./encounters");
opendir(DIR,$odir) or die $!;
my @files = grep {
		/\.xml$/
		&& -f "$odir/$_"
	} readdir(DIR);
closedir(DIR);
foreach my $f (@files) {
	$filebox->insert( Button => text => $f, onClick => sub { PGUI::openEncounter($opponentpage,$f); $filebox->destroy(); });
}
$opponentpage->insert( SpeedButton => text => "Add Opponent", pack => {fill => 'none', expand => 0} );
#	encounter managing tab
$color = Common::getColors($i++,1);
my $timepage = $pager->insert_to_page(2,VBox =>
		backColor => ColorRow::stringToColor($color),
		pack => { fill => 'both', },
	);
#my $startbut = $timepage->insert( SpeedButton => text => "Start Encounter", pack => { fill => 'none', expand => 0} );
my $hb = $timepage->insert( HBox => name => 'timesplit' );
my $initiative = initBox->new( round => 0, box => $hb->insert( VBox => name => 'ib', pack => {fill => 'both', expand => 1} ));
#$startbut->onClick( sub {
#	foreach (@partymembers) {
#		print "$_->{name}: $_->{priority}\n";
#	}
#	$initiative->startEncounter($hb);
#	$startbut->destroy();
#});
my $statuses = $hb->insert( VBox => name => "status", pack => {fill => 'both', expand => 1});
$statuses->insert( Label => text => "Status:" );
# display windows


my $text = $$gui{status};
$text->push("Ready.");
Prima->run();

use Data::Dumper;
print Dumper @partymembers;
