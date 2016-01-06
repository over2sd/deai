package PGUI;
print __PACKAGE__;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( );

use FIO qw( config );

=head1 NAME

PGUI - A module for Prima GUI elements

=head2 DESCRIPTION

A library of functions used to build and manipulate the program's Prima user interface elements.

=cut

package initBox;

sub new {
	my ($class,%profile) = @_;
	unless (defined $profile{tbox}) {
		die "An initBox must be given a VBox or HBox timebox parameter, e.g., tbox => \$parent->insert(VBox => name => 'boxy')";
	}
	unless (defined $profile{sbox}) {
		die "An initBox must be given a VBox or HBox statusbox parameter, e.g., sbox => \$parent->insert(VBox => name => 'boxy')";
	}
	my $self = {
		box => $profile{tbox},
		round => ($profile{round} or 0),
		priority => [],
		slist => $profile{sbox},
		rlabel => undef,
	};
	bless $self,$class;
	$self->build($self->{box});
	return $self;
}

sub insert {
	my ($self,@parms) = @_;
	my $box = $self->{box};
	return $box->insert(@parms);
}

sub build {
	my ($self,$box,$stat) = @_;
	defined $box or $box = $self->{box};
	defined $stat or $stat = $self->{slist};
	my $button = $box->insert(SpeedButton => text => "Begin Encounter");
	$button->onClick(sub { $button->destroy(); $self->startEncounter($box);});
	$stat->insert( Label => text => "Status:" );
	$self->{rlabel} = $stat->insert( Label => text => "Round $self->{round}");
	$stat->{rows} = $stat->insert( VBox => name => 'rowcontainer', pack => { fill => 'both', expand => 1});
}

sub startEncounter {
	my ($self,$box,$stat) = @_;
	defined $box or $box = $self->{box};
	my $party = Sui::passData('party');
	my $mobs = Sui::passData('enemies');
	unless (defined $party and scalar @$party) {
		my $warn = $box->insert(Label => text => "No party found.\nThe forces of darkness prevail.\nAdd party members to start an encounter.", autoHeight => 1);
		my $button = $box->insert(SpeedButton => text => "Begin Encounter");
		$button->onClick(sub { $warn->destroy(); $button->destroy(); $self->startEncounter($box);});
		return;
	}
	unless (defined $mobs and scalar @$mobs) {
		my $warn = $box->insert(Label => text => "No enemies found.\nParty unchallenged.\nAdd enemies to begin an encounter.", autoHeight => 1);
		my $button = $box->insert(SpeedButton => text => "Begin Encounter");
		$button->onClick(sub { $warn->destroy(); $button->destroy(); $self->startEncounter($box);});
		return;
	}
	$box->insert(Label => text => "Current actor:", pack => {fill => 'x'});
	my %inits;
#	my @priority;
	foreach my $m (@$party,@$mobs) {
		my $key = sprintf("%03d",$m->get('priority'));
		defined $inits{$key} or $inits{$key} = [];
		push(@{ $inits{$key} },$m);
	}
	foreach my $k (reverse sort keys %inits) {
		my $list = $inits{$k};
		my @imods;
		foreach (@$list) {
			push(@imod,$_->get('init'));
		}
		my ($elist,$ilist) = Common::listSort(\@imods,@$list);
#		push(@priority,reverse @$elist);
		push(@{ $self->{priority} },reverse @$elist);
	}
#print "\nContains:\n";
#foreach (@priority) {
#	printf("%s: %d/%d\n",$_->get('name'),$_->get('priority'),$_->get('init'));
#}
	my $rounds = TurnMarker->new($self);
	$self->enqueue($rounds); # add the end-of-turn marker
	defined $stat or $stat = $self->{slist};
	my $inames = [];
	foreach my $m (@$party,@$mobs) {
		push(@{ $inames },$m->get('name'));
	}
	my ($elist,$ilist) = Common::listSort(\@inames,@$party,@$mobs);
	my $rows = $stat->{rows};
	foreach my $m (@$elist) {
		$color = Common::getColors(($i++ % 2 ? 0 : 14),1);
		$m->makeStatusRow($rows,$self,$color);
	}
	$self->incRound();
	$self->advance();
}

sub advance {
	my ($self) = @_;
	my $x = shift @{ $self->{priority} } or return -1;
	$x->activate($self);
	return 0;
}

sub enqueue {
	my ($self,$object) = @_;
	(defined $object or return -1);
	push(@{ $self->{priority} },$object);
	return 0;
}

sub incRound {
	my $self = shift;
	$self->{round}++;
	my $sl = $self->{slist};
	# update slist's round label
	my $rl = 	$self->{rlabel};
	$rl->text(sprintf("Round %d",$self->{round}));
	# run through slist's rows of entities, checking for expiration of effects
}

package PGUI;
sub populateMainWin {
	my ($dbh,$gui,$refresh,$campdir) = @_;
	($refresh && $$gui{pager}->destroy());
	my $win = $$gui{mainWin};
	# load party
	my $output = $win->insert(StatBox => name => "status");
	my ($party,$error) = deaiXML::fromXML(sprintf("%s/%s",$campdir,FIO::config('Main','partyfn')),$output);
	(defined $party or die $error); # TODO replace die with a dialog for entering a new party member.
	my @partymembers = ();
	foreach my $p (@$party) {
		my $m = PC->new(%$p);
		push(@partymembers,$m);
	}
	Sui::storeData('party',\@partymembers);
	Sui::storeData('enemies',[]);
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
	$partypage->insert( SpeedButton => text => "Add Party Member", pack => {fill => 'none', expand => 0},
		onClick => sub { PGUI::addMember($_[0],'party',$partypage,$color); },
		);
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
	my $odir = sprintf("%s/%s",$campdir,(FIO::config('Main','oppdir') or "encounters"));
	opendir(DIR,$odir) or die $!;
	my @files = grep {
		/\.xml$/
		&& -f "$odir/$_"
		} readdir(DIR);
	closedir(DIR);
	foreach my $f (@files) {
		$filebox->insert( Button => text => $f, onClick => sub { PGUI::openEncounter($opponentpage,"$odir/$f"); $filebox->destroy(); });
	}
	$opponentpage->insert( SpeedButton => text => "Add Opponent", pack => {fill => 'none', expand => 0},
		onClick => sub { $filebox->destroy(); PGUI::addMember($_[0],'enemies',$opponentpage,$color); },
	);
	#	encounter managing tab
	$color = Common::getColors($i++,1);
	my $timepage = $pager->insert_to_page(2,VBox =>
			backColor => ColorRow::stringToColor($color),
			pack => { fill => 'both', },
		);
	my $hb = $timepage->insert( HBox => name => 'timesplit', pack => {fill => 'both', expand => 1} );
	my $initiative = initBox->new( round => 0, tbox => $hb->insert( VBox => name => 'ib', pack => {fill => 'both', expand => 1} ), sbox => $hb->insert( VBox => name => "status", pack => {fill => 'both', expand => 1}));
	$$gui{pager} = $pager;
}
print ".";

sub buildMenus { #Replaces Gtk2::Menu, Gtk2::MenuBar, Gtk2::MenuItem
	my $gui = shift;
	my $menus = [
		[ '~File' => [
			['~New Campaign','Ctrl-N','^N',sub { $$gui{pager}->destroy(); PGUI::createCampaign($gui); }],
			['~Load Campaign','Ctrl-L','^L',sub { $$gui{pager}->destroy(); config('Main','nocampask',0); PGUI::selectCamp($gui); } ],
#			['~Save Party', 'Ctrl-S', '^S', sub { message('synch!') }],
			['~Preferences', sub { return callOptBox($gui); }],
			[],
			['Close', 'Ctrl-W', km::Ctrl | ord('W'), sub { $$gui{mainWin}->close() } ],
		]],
		[ '~Help' => [
			['~About',sub { message('About!') }], #\&aboutBox],
		]],
	];
	return $menus;
}
print ".";

sub sayBox {
	my ($parent,$text) = @_;
	message($text,owner=>$parent);
}
print ".";

sub callOptBox {
	my $gui = shift || getGUI();
	my %options = Sui::passData('opts');
	return Options::mkOptBox($gui,%options);
}
print ".";

=item devHelp PARENT UNFINISHEDTASK

Displays a message that UNFINISHEDTASK is not done but is planned.
TODO: Remove from release.
No return value.

=cut
sub devHelp {
	my ($target,$task) = @_;
	sayBox($target,"$task is on the developer's TODO list.\nIf you'd like to help, check out the project's GitHub repo at http://github.com/over2sd/pomal.");
}
print ".";

sub openEncounter {
	my ($box,$encfn) = @_;
	my @olist;
	my $tmp = $box->insert(StatBox => name => 'temp');
	my ($group,$error) = deaiXML::fromXML($encfn,$tmp);
	(defined $group or print $error);
	my @members = ();
	foreach my $d (@$group) {
		my $m = Mob->new(%$d);
		push(@members,$m);
	}
	Sui::storeData('enemies',\@members);
	$tmp->destroy();
	my $i = 0;
	foreach (@members) {
		my $color = Common::getColors(($i++ % 2 ? 0 : 14),1);
		$_->makeRow($box,$color);
	}

}
print ".";

sub addMember {
	my ($caller,$memtyp,$target,$color) = @_;
	return unless ($memtyp eq 'party' or $memtyp eq 'enemies');
	$caller->enabled(0);
	my $members = (Sui::passData($memtyp) or []);
	my $topper = $target->insert( Label => text => "Enter member details:" );
	my $row1 = $target->insert( HBox => name => 'addmember1' );
	my $m = PC->new();
	$row1->insert( Label => text => "AC:");
	my $size = PGK::labelBox($row1,'Size','acz','v',boxex => 0, labex => 0);
	$size->insert( SpinEdit => value => 0, onChange => sub { $m->{size} = $_[0]->text; });
	my $armor = PGK::labelBox($row1,'Armor','aca','v',boxex => 0, labex => 0);
	$armor->insert( SpinEdit => value => 0, onChange => sub { $m->{armor} = $_[0]->text; });
	my $shield = PGK::labelBox($row1,'Shield','acs','v',boxex => 0, labex => 0);
	$shield->insert( SpinEdit => value => 0, onChange => sub { $m->{shield} = $_[0]->text; });
	my $dex = PGK::labelBox($row1,'Dex mod','acd','v',boxex => 0, labex => 0);
	$dex->insert( SpinEdit => value => 0, onChange => sub { $m->{dexmod} = $_[0]->text; });
	my $nat = PGK::labelBox($row1,'Natural','acn','v',boxex => 0, labex => 0);
	$nat->insert( SpinEdit => value => 0, onChange => sub { $m->{nat} = $_[0]->text; });
	my $deflect = PGK::labelBox($row1,'Deflect','ace','v',boxex => 0, labex => 0);
	$deflect->insert( SpinEdit => value => 0, onChange => sub { $m->{deflect} = $_[0]->text; });
	my $notff = PGK::labelBox($row1,'NotFF','acf','v',boxex => 0, labex => 0);
	$notff->insert( SpinEdit => value => 0, onChange => sub { $m->{notff} = $_[0]->text; });
	my $nottch = PGK::labelBox($row1,'NotTouch','act','v',boxex => 0, labex => 0);
	$nottch->insert( SpinEdit => value => 0, onChange => sub { $m->{nottch} = $_[0]->text; });
	my $misc = PGK::labelBox($row1,'Misc','acm','v',boxex => 0, labex => 0);
	$misc->insert( SpinEdit => value => 0, onChange => sub { $m->{miscmod} = $_[0]->text; });
	my $row2 = $target->insert( HBox => name => 'addmember2', pack => {fill => 'x'} );
	my $name = PGK::labelBox($row2,'Name','name','v',boxex => 0, labex => 0);
	$name->insert( InputLine => text => '', onChange => sub { $m->{name} = $_[0]->text; });
	my $pname = PGK::labelBox($row2,'Player','name','v',boxex => 0, labex => 0);
	$pname->insert( InputLine => text => 'GM', onChange => sub { $m->{player} = $_[0]->text; });
	my $speed = PGK::labelBox($row2,'Speed','spd','v',boxex => 0, labex => 0);
	$speed->insert( SpinEdit => value => 30, onChange => sub { $m->{speed} = $_[0]->text; });
	my $maxhp = PGK::labelBox($row2,'HP','mhp','v',boxex => 0, labex => 0);
	$maxhp->insert( SpinEdit => value => 1, onChange => sub { $m->{maxhp} = $_[0]->text; });
	my $con = PGK::labelBox($row2,'Con Score','con','v',boxex => 0, labex => 0);
	$con->insert( SpinEdit => value => 10, onChange => sub { $m->{conscore} = $_[0]->text; });
	my $init = PGK::labelBox($row2,'Init Bonus','init','v',boxex => 0, labex => 0);
	$init->insert( SpinEdit => value => 1, onChange => sub { $m->{init} = $_[0]->text; });
	$row2->insert( SpeedButton => text => "Save",
		onClick => sub {
			($m->{name} eq '' && return);
			push(@$members,$m);
			$m->makeRow($target,$color);
			$topper->destroy();
			$row1->destroy();
			$row2->destroy();
			$caller->enabled(1);
		}
		);
	return 0;
}

print ".";

sub selectCamp {
	my ($gui) = @_;
	my $win = $$gui{mainWin};
	my $cdir = (FIO::config('Main','campdir') or "./campaigns");
	if (FIO::config('Main','nocampask')) {
		my $campdir = (FIO::config('Main','usecamp') or "./campaigns/default");
		populateMainWin(undef,$gui,0,$campdir);
		return; # don't ask
	}
	opendir(DIR,$cdir) or die $!;
	my $lister = $win->insert( VBox => name => "Campaigns", pack => {fill => 'both', expand => 1} );
	$lister->insert( Label => text => "Choose your campaign");
	my @dirs = grep {
		!/^\.\.?$/
		&& -d "$cdir/$_"
	} readdir(DIR);
	closedir(DIR);
	foreach my $d (@dirs) {
		$lister->insert( Button => text => $d, onClick => sub { $lister->destroy();
			my $campdir = sprintf("%s/%s",$cdir,$d);
			(FIO::config('Main','nocampask') && FIO::config('Main','usecamp',$campdir) &&  FIO::saveConf()); # store this campaign if we don't want to be asked again
			populateMainWin(undef,$gui,0,$campdir);
		});
	}
	$lister->insert( CheckBox => text => "Always use this campaign", onClick => sub { FIO::config('Main','nocampask',($_[0]->checked ? 1 : 0)); FIO::saveConf(); });
	$lister->insert( Button => text => "Create a New Campaign", onClick => sub { FIO::config('Main','nocampask',0); $lister->destroy(); PGUI::createCampaign($gui); });
}

print ".";

sub createCampaign {
	my ($gui) = @_;
	my $win = $$gui{mainWin};
	my $cdir = (FIO::config('Main','campdir') or "./campaigns");
	my $row = $win->insert( HBox => name => 'newcamp');
	$row->insert( Label => text => "New campaign to be created in $cdir/");
	my $dname = $row->insert( InputLine => text => "bestcampaignever" );
	$row->insert( SpeedButton => text => "Create", onClick => sub { $_[0]->destroy(); reallyCreateCampaign($gui,$cdir,$dname->text)});
}
print ".";

sub reallyCreateCampaign {
	my ($gui,$cdir,$newdir) = @_;
	my $odir = (FIO::config('Main','oppdir') or "encounters");
	mkdir "$cdir/$newdir";
	mkdir "$cdir/$newdir/$odir";
	my $text = "<group>\n<comment>This file hasn't been edited. Use member tags to store information about members of this group.</comment>\n</group>\n";
	unless (open(FILE,sprintf(">$cdir/$newdir/%s",FIO::config('Main','partyfn')))) {
		$win->insert( Label => text => "Error opening file: $!" );
		$win->insert( Button => text => "Exit", onClick => sub { $win->close() });
		return;	
	};
	print FILE $text;
	close(FILE);
	unless (open(FILE,sprintf(">$cdir/$newdir/$odir/basic.xml"))) {
		$win->insert( Label => text => "Error opening file: $!" );
		$win->insert( Button => text => "Exit", onClick => sub { $win->close() });
		return;	
	};
	print FILE $text;
	close(FILE);
	my $win = $$gui{mainWin};
	PGK::sayBox($win,"Your campaign has been created\n in $cdir/$newdir.\n You must add entities to play.");
	populateMainWin(undef,$gui,0,"$cdir/$newdir");
}
print ".";


print " OK; ";
1;
