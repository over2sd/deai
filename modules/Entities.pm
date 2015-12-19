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
	my $row = $display->insert( HBox => name => $self->get('name'), pack => {fill => 'x'});
	$row->insert( Label => text => $self->get('name'));
	my $act = $row->insert( SpeedButton => text => "Act");
	$act->onClick(sub {
		$display->enqueue($self);
		$row->destroy();
		$display->advance();
	});
	my $wait = $row->insert( SpeedButton => text => "Delay");
	$wait->onClick( sub {
		$wait->enabled(0);
		my $skip = Skipper->new($display,$row,$self);
		FIO::config('UI','waittoskip') && $display->enqueue($skip);
		$act->onClick(sub {
			$display->enqueue($self);
			FIO::config('UI','waittoskip') && $skip->disable();
			$row->destroy();
		});
		$display->advance();
		$wait->destroy();
	});
}

sub makeRow {
	my ($self,$display,$color) = @_;
	my $row = $display->insert(HBox => name => $self->{name}, pack => { fill => 'x', expand => 0}, backColor => ColorRow::stringToColor($color or "#9cc"));
	$row->insert( Widget => width => 7, height => 30, backColor => ColorRow::stringToColor($color or "#9cc") );
	my $name = Common::shorten($self->{name},(FIO::config('UI','namelimit') or 20),4);
	$row->insert( Label => text => "$name:", pack => {fill => 'x', expand => 1} );
	$row->insert( Label => text => "Initiative: ");
	$row->insert( InputLine => text => ($self->{priority} == 99 ? "" : $self->{priority}), onChange => sub { $self->{priority} = int($_[0]->text); });
	$self->{curhp} = $self->{maxhp}; # for use in encounters
}

sub makeStatusRow {
	my ($self,$target,$color) = @_;
	my $name = Common::shorten($self->{name},(FIO::config('UI','namelimit') or 20),4);
	my $row = $target->insert( HBox => name => 'row', backColor => ColorRow::stringToColor($color or "#99f"), pack => {fill => 'x', expand => 0} );
	$row->insert( Label => text => " $name: ");
	$row->insert( SpeedButton => text => sprintf(" %d/%d ",$self->{curhp},$self->{maxhp}),
		onClick => sub { print "HP clicked";},
	);
	$row->insert( Label => text => "  AC: " . $self->ac('full') . " ");
	return $row;
}

sub ac {
	my ($self,$which) = @_;
	my $ac = (FIO::config('Main','baseAC') or 10);
	for ($which) {
		if (/full/) {
			return sprintf("%s/%s/%s",$self->ac('n'),$self->ac('f'),$self->ac('t'));
		} elsif (/f/) {
			$ac += $self->{size};
			$ac += $self->{armor};
			$ac += $self->{shield};
			$ac += $self->{nat};
			$ac += $self->{deflect};
			$ac += $self->{nottch};
			$ac += $self->{miscmod};
			return $ac;
		} elsif (/t/) {
			$ac += $self->{size};
			$ac += $self->{dexmod};
			$ac += $self->{deflect};
			$ac += $self->{notff};
			$ac += $self->{miscmod};
			return $ac;
		} else {
			$ac += $self->{size};
			$ac += $self->{armor};
			$ac += $self->{shield};
			$ac += $self->{dexmod};
			$ac += $self->{nat};
			$ac += $self->{deflect};
			$ac += $self->{notff};
			$ac += $self->{nottch};
			$ac += $self->{miscmod};
			return $ac;
		}
	}
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
	my ($self,$display) = @_;
	(defined $display or $display = $self->{parent});
	# increment round number in parent
	$display->incRound();
	# add new round marker to end of parent's queue
	$display->enqueue($self);
	$display->advance();
}

print ".";

package Skipper;

sub new {
	my ($class,$parent,$box,$char,%profile) = @_;
	die "No parent given to turn marker!" unless (defined $parent);
	my $self = {
		%profile,
		parent => $parent,
		waiter => $box,
		char => $char,
		enabled => 1,
	};
	bless $self,$class;
	return $self;
}

sub activate {
	my ($self,$display) = @_;
	(defined $display or $display = $self->{parent});
	if ($self->{enabled}) {
		$self->{waiter}->destroy();
		$self->{char}->activate($display);
	} else {
		$display->advance();
	}
}

sub disable {
	$_[0]->{enabled} = 0;
}

print ".";

print " OK; ";
1;
