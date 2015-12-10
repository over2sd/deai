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
	unless (defined $profile{box}) {
		die "An initBox must be given a VBox or HBox parameter, e.g., box => \$parent->insert(VBox => name => 'boxy')";
	}
	my $self = {
		box => $profile{box},
		round => ($profile{round} or 0),
		priority => [],
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
	my ($self,$box) = @_;
	defined $box or $box = $self->{box};
	my $button = $box->insert(SpeedButton => text => "Begin Encounter");
	$button->onClick(sub { $button->destroy(); $self->startEncounter($box);});
}

sub startEncounter {
	my ($self,$box) = @_;
	defined $box or $box = $self->{box};
	my $party = Sui::passData('party');
	my $mobs = Sui::passData('enemies');
	unless (defined $party) {
		$box->insert(Label => text => "No party found. The forces of darkness prevail. Add party members to start an encounter.");
		my $button = $box->insert(SpeedButton => text => "Begin Encounter");
		$button->onClick(sub { $button->destroy(); $self->startEncounter($box);});
		return;
	}
	unless (defined $mobs) {
		$box->insert(Label => text => "No enemies found. Party unchallenged. Add enemies to begin an encounter.");
		my $button = $box->insert(SpeedButton => text => "Begin Encounter");
		$button->onClick(sub { $button->destroy(); $self->startEncounter($box);});
		return;
	}
	my %inits;
	my @priority;
	foreach my $m (@$party) {
		my $key = sprintf("%03d",$m->get('priority'));
		defined $inits{$key} or $inits{$key} = [];
		push(@{ $inits{$key} },$m);
	}
	foreach my $m (@$mobs) {
		my $key = sprintf("%03d",$m->get('priority'));
		defined $inits{$key} or $inits{$key} = [];
		push(@{ $inits{$key} },$m);
	}
	foreach my $k (reverse keys %inits) {
		my @list = @{ $inits{$key} };
		my @imods;
		foreach (@list) {
			push(@imod,$_->get('init'));
		}
		my ($elist,$ilist) = Common::listSort(\@imods,@list);
		push(@priority,@$elist);
		push(@{ $self->{priority} },@$elist);
	}
use Data::Dumper;
print Dumper @priority;
}

package PGUI;
sub populateMainWin {
	my ($dbh,$gui,$something) = @_;
}
print ".";

sub buildMenus { #Replaces Gtk2::Menu, Gtk2::MenuBar, Gtk2::MenuItem
	my $gui = shift;
	my $menus = [
		[ '~File' => [
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


print " OK; ";
1;
