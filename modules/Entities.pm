package Entities;
print __PACKAGE__;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( PC Mob );

use FIO qw( config );

=head1 NAME

Entities - A module for functions and objects related to PCs, NPCs, mobs, and other RPG entities

=head2 DESCRIPTION

A library of functions usable by entities and their objects.

=cut
package PC; # Player character

=head2 PC

Player Character entity. Stores a PC's information

=head3 Usage

  my $gandalf = PC->new(name => "Gandalf", dexmod => 3, conscore => 14, maxhp => 27, init => 7);

=cut
sub new {
	my ($class,%profile) = @_;
	my $self = {
# 	dexmod nat deflect notff nottch miscmod speed conscore maxhp init );
		name => ($profile{name} or "Unnamed"),
		player => ($profile{player} or "GM"),
		mini => ($profile{mini} or "d6"),
		size => ($profile{size} or 0),
		armor => ($profile{armor} or 0),
		shield => ($profile{shield} or 0),
		dexmod => ($profile{dexmod} or 0),
		nat => ($profile{nat} or 0),
		deflect => ($profile{deflect} or 0),
		notff => ($profile{notff} or 0),
		nottch => ($profile{nottch} or 0),
		miscmod => ($profile{miscmod} or 0),
		speed => ($profile{speed} or 30),
		conscore => ($profile{conscore} or 0),
		maxhp => ($profile{maxhp} or 0),
		init => ($profile{init} or 0),
		priority => 99,
		nextact => 1,
	};
	bless $self, $class;
	return $self;
}

sub get {
	my ($self,$key) = @_;
	defined $key or return undef;
	return $self->{$key};
}

sub set {
	my ($self,$key,$value) = @_;
	defined $value and defined $key or return undef;
	$self->{$key} = $value;
	return $self->{$key};
}

sub increase {
	my ($self,$key,$value) = @_;
	defined $value and defined $key or return undef;
# TODO: check for numeric
	$self->{$key} += $value;
	return $self->{$key};
}

sub decrease {
	my ($self,$key,$value) = @_;
	defined $value and defined $key or return undef;
# TODO: check for numeric
	$self->{$key} -= $value;
	return $self->{$key};
}

sub activate {
	my ($self,$display) = @_;
	# insert display row with buttons into display
	# onClick of act button, add self to end of display's queue, destroy display row, ask display to read next item in queue
	# onClick of wait button, disable wait button, ask display to read next item in queue, and destroy wait button
}

sub makeRow {
	my ($self,$display,$color) = @_;
	my $row = $display->insert(HBox => name => $self->{name}, pack => { fill => 'x', expand => 0}, backColor => ColorRow::stringToColor($color or "#9cc"));
	$row->insert( Widget => width => 7, height => 30, backColor => ColorRow::stringToColor($color or "#9cc") );
	$row->insert( Label => text => "$self->{name}:", pack => {fill => 'x', expand => 1} );
	$row->insert( Label => text => "Initiative: ");
	$row->insert( InputLine => text => ($self->{priority} == 99 ? "" : $self->{priority}), onChange => sub { $self->{priority} = int($_[0]->text); });
}
print ".";

package Mob; # monsters, hostile NPCs, etc.
use vars qw(@ISA);
@ISA = qw(PC);

sub new {
	my ($class,%profile) = @_;
	my $self = PC->new(%profile);
	foreach (qw( pp gp sp cp sr cr )) {
		$self->{$_} = ($profile{$_} or 0);
	}
 	foreach (qw( loot0 loot5 loot10 loot15 loot20 loot25 dr race type )) {
		$self->{$_} = ($profile{$_} or "");
	}
	bless $self,$class;
	return $self;
}

print ".";

package TurnMarker;

sub new {
	my ($class,$parent,%profile) = @_;
	die "No parent given to turn marker!" unless (defined $parent);
	my $self = {
		%profile,
		parent => $parent,
	};
	bless $self,$class;
	return $self;
}

sub activate {
	# increment round number in parent
	# add new round marker to end of parent's queue
}

print ".";

print " OK; ";
1;
