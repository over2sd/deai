package deaiXML;
print __PACKAGE__;

use FIO qw( config );

sub fromXML {
	$|++;
	require XML::LibXML::Reader;
	my ($fn,$output) = @_;
	my $xml = XML::LibXML::Reader->new(location => $fn)
		or return undef,"Cannot read $fn!";
	$output and $output->push("Attempting to import $fn...");
	my $storecount = 0;
	my $list = [];
	my $termcolor = config('Debug','termcolors') or 0;
	use Common qw( getColorsbyName );
	my $infcol = ($termcolor ? Common::getColorsbyName("green") : "");
	my $basecol = ($termcolor ? Common::getColorsbyName("base") : "");
	my $pccol = ($termcolor ? Common::getColorsbyName("cyan") : "");
	my $npccol = ($termcolor ? Common::getColorsbyName("ltblue") : "");
	my $loop = $xml->read();
	$::application->yield();
	while ($loop == 1) {
		$::application->yield();
		if ($xml->nodeType() == 8) { print "\nComment in XML: " . $xml->value() . "\n"; $loop = $xml->next(); next; } # print comments and skip processing
		if ($xml->nodeType() == 13 or $xml->nodeType() == 14 or $xml->name() eq "group") {
#			$i--;
			$loop = $xml->read(); next; } # skip whitespace (and root node)
		for ($xml->name()) {
			if(/^member$/) {
				print "m";
				my $node = $xml->copyCurrentNode(1);
				$::application->yield();
				my $error = pushMember($list,$node,$termcolor,$pccol);
				unless ($error) { $storecount++; } # increase count of titles successfully stored
				$loop = $xml->next();
				print " ";
			} elsif (/^comments$/) {
				print "Comment\n";
			} else {
				printf "\n%s %d %d <%s> %d\n", ($xml->value or "", $xml->depth,$xml->nodeType,$xml->name,$xml->isEmptyElement);
			}
		}
		$loop = $xml->read();
#		$i++; # TODO: remove this temporary limiter
#		if ($i > 30) { $loop = 0; } # to shorten test runs
	}
	print "\n";
	$|--;
	$output->push("Successfully imported $storecount members...");
	$xml->close();
	return $list;
}
print ".";

sub toXML {
	my ($win,$list,$fn) = @_;
	# unless fn defined, ask for it
	my @members = @$list or die "toXML was not provided with a valid arrayref";
	my $grouptype = ref($members[0]); # assuming you've sensibly sent me a homogenous group. You should not try to save PCs and Mobs in the same group, anyway.
	unless (defined $fn) {
		$fn = PGK::askbox($win,"Filename...",{one => 'tmp.xml'},"To what file should these be saved?") or undef;
		($grouptype eq "Mob" && ($fn = sprintf("%s/%s",(FIO::config('Main','oppdir') or "encounters"),$fn)));
		$fn = sprintf("%s/%s",FIO::config('Main','currentcamp'),$fn);
	}
	$|++;
	require XML::LibXML;
	my $out = XML::LibXML::Document->new();
	my $root = $out->createElement('group');
	$out->setDocumentElement($root);
	my @pctags = qw( name player mini size armor shield dexmod nat deflect notff nottch miscmod speed conscore maxhp init );
	my @mobtags = qw( pp gp sp cp sr cr loot0 loot5 loot10 loot15 loot20 loot25 dr race type );
	foreach my $m (@members) {
		my $e = $out->createElement('member');
		$root->appendChild($e);
		foreach my $tag (@pctags) {
			my $text = sprintf("%s",($m->{$tag} or ""));
			($text ne '') or next;
			my $t = $out->createElement($tag);
			$e->appendChild($t);
			$t->appendChild(XML::LibXML::Text->new($text));
		}
		($grouptype eq "Mob" || next);
		foreach my $tag (@mobtags) {
			my $text = sprintf("%s",($m->{$tag} or ""));
			($text ne '') or next;
			my $t = $out->createElement($tag);
			$e->appendChild($t);
			$t->appendChild(XML::LibXML::Text->new($text));
		}
	}
	$|--;
	print "Saving $fn...\n";
	unless (open(FILE,">$fn")) {
		$win->insert( Label => text => "Error opening file: $!" );
		$win->insert( Button => text => "Exit", onClick => sub { $win->close() });
		return;	
	};
	print FILE $out->toString(2);
	close(FILE);
}
print ".";

sub pushMember {
	my ($listref,$node,$termcolor,$thiscol) = @_;
	my $basecol = ($termcolor ? Common::getColorsbyName("base") : "");
	my %data;
	$::application->yield();
	if ($termcolor) { print $thiscol; }
	my @tags = qw( name player mini size armor shield dexmod nat deflect notff nottch miscmod speed conscore maxhp init pp gp sp cp sr cr loot0 loot5 loot10 loot15 loot20 loot25 dr race type );
	foreach (@tags) {
		$child = @{ $node->getChildrenByTagName($_) or [] }[0];
		if (defined $child and $child->textContent() ne "") { print "."; $data{$_} = $child->textContent(); }
	}
	if ($termcolor) { print $basecol; }
	push(@{ $listref },\%data);
	return 0;
}
print ".";

print " OK; ";
1;
