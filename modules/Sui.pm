package Sui; # Self - Program-specific data storage
print __PACKAGE__;

=head1 Sui

Keeps common modules as clean as possible by storing program-specific
data needed by those common-module functions in a separate file.

=head2 passData STRING

Passes the data identified by STRING to the caller.
Returns some data block, usually an arrayref or hashref, but possibly
anything. Calling programs should be carefully written to expect what
they're asking for.

=cut

my %data = (
	dbname => 'pomal',
	dbhost => 'localhost',
	tablekeys => {
#		series_extra => ['alttitle',], #		pub_extra => ['alttitle',]
			series => ['sname','episodes','lastwatched','started','ended','score','content','rating','lastrewatched','seentimes','status','note','stype'],
			pub => ['pname','volumes','chapters','lastreadc','lastreadv','started','ended','score','content','rating','lastreread','readtimes','status','note'],
			extsid => ['mal','hum'],
			extpid => ['mal','hum'],
			episode => ['ename','score','content','rating','firstwatch'],
			volume => ['vname','score','content','rating','firstread'],
			chapter => ['cname','score','content','rating','firstread'],
		},
	tableids => { series => "sid", pub => "pid", extsid => "sid", extpid => "pid", },
	objectionablecontent => [ 'nudity','violence','language','sex','brutality','blasphemy','horror','nihilism','theology','occult','superpowers','rape','fanservice','drugs','hentai','gambling','war','discrimination'],
	disambiguations => {
		tag => ["tag_(context1)","tag_(context2)"],
		othertag => ["othertag_(context1)","othertag_(context2)"]
	},
);

sub passData {
	my $key = shift;
	for ($key) {
		if (/^opts$/) {
			return getOpts();
		} elsif (/^twidths$/) {
			return getTableWidths();
		} else {
			return $data{$key} or undef;
		}
	}
}
print ".";

sub storeData {
	my ($key,$value) = @_;
	defined $key and defined $value or return undef;
	return $data{$key} = $value;
}
print ".";

# Status hashes
sub getStatHash { my $typ = shift; return (wat=>($typ eq 'man' ? "Read" : "Watch") . "ing",onh=>"On-hold",ptw=>"Plan to " . ($typ eq 'man' ? "Read" : "Watch"),com=>"Completed",drp=>"Dropped"); } # could be given i18n
sub getStatOrder { return qw( wat onh ptw com drp ); }
sub getStatIndex { return ( ptw => 0, wat => 1, onh => 2, rew => 3, com => 4, drp => 5 ); }
sub getStatArray {
	my $sa = [];
	my %stats = (getStatHash(shift),rew=>"Re" . ($typ eq 'man' ? "read" : "watch") . "ing");
	foreach (qw( ptw wat onh rew com drp )) {
		push(@$sa,$stats{$_});
	}
	return $sa;
}
print ".";

sub getOpts {
	# First hash key (when sorted) MUST be a label containing a key that corresponds to the INI Section for the options that follow it!
	# EACH Section needs a label conaining the Section name in the INI file where it resides.
	my %opts = (
		'000' => ['l',"General",'Main'],
		'001' => ['c',"Save window positions",'savepos'],
##		'002' => ['x',"Foreground color: ",'fgcol',"#00000"],
##		'003' => ['x',"Background color: ",'bgcol',"#CCCCCC"],
		'004' => ['c',"Errors are fatal",'fatalerr'],
		'005' => ['t',"Filename for party",'partyfn'],
		'006' => ['t','Campaign directory','campdir'],
		'007' => ['t','Opponent subdirectory','oppdir'],
		'008' => ['t','Campaign default','usecamp'],
		'009' => ['c','Always use default','nocampask'],
		'00a' => ['c',"Tiebreaking: High initiative goes first",'highinitfirst'],

		'030' => ['l',"User Interface",'UI'],
		'031' => ['c',"Delay skips if no action before next turn",'waittoskip'],
		'032' => ['n',"Shorten names to this length",'namelimit',20,15,100,1,10],
		'039' => ['x',"Header background color code: ",'headerbg',"#CCCCFF"],
		'03a' => ['c',"Show count in section tables",'linenos'],
		'03d' => ['x',"Background for list tables",'listbg',"#EEF"],
		'043' => ['x',"Background for letter buttons",'letterbg',"#CFC"],
		'040' => ['c',"Show a horizontal rule between rows",'rulesep'],
		'041' => ['x',"Rule color: ",'rulecolor',"#003"],

		'050' => ['l',"Recent",'Recent'],
		'051' => ['c',"Recent tab is active on startup",'activerecent'],
		'052' => ['c',"Show episode scores as text",'hiddenepgraph'],
		'05f' => ['n',"Maximum recent portions to display on recent tab",'reclimit',5,1,20,1,5],

		'750' => ['l',"Fonts",'Font'],
		'754' => ['f',"Tab font/size: ",'label'],
		'751' => ['f',"General font/size: ",'body'],
		'755' => ['f',"Special font/size: ",'special'], # for lack of a better term
		'752' => ['f',"Progress font/size: ",'progress'],
		'753' => ['f',"Progress Button font/size: ",'progbut'],
		'754' => ['f',"Major heading font/size: ",'bighead'],
		'755' => ['f',"Heading font/size: ",'head'],
		'756' => ['f',"Sole-entry font/size: ",'bigent'],

		'870' => ['l',"Custom Text",'Custom'],
		'872' => ['t',"Anime:",'ani'],
		'873' => ['t',"Manga:",'man'],
		'871' => ['t',"DEAI:",'program'],
##		'874' => ['t',"Movies:",'mov'],
##		'875' => ['t',"Stand-alone Manga:",'sam'],
		'876' => ['t',"Options dialog",'options'],

		'877' => ['l',"Table",'Table'],
		'878' => ['c',"Statistics summary",'statsummary'],
		'879' => ['c',"Stats include median score",'withmedian'],
		'87f' => ['g',"Column Widths",'label'],
		'880' => ['n',"Row #s",'t1c0',21,0,800,1,10],
		'881' => ['n',"Rewatch/Move",'t1c1',140,0,800,1,10],
		'882' => ['n',"Progress",'t1c2',105,0,800,1,10],
		'883' => ['n',"Score",'t1c3',51,0,800,1,10],
#		'884' => ['n',"Tags",'t1c4',60,0,800,1,10],
#		'885' => ['n',"Column 5",'t1c5',0,0,800,1,10],
#		'886' => ['n',"View",'t1c6',60,0,800,1,10],
		'88a' => ['g',"Rows:",'label'],
		'88b' => ['n',"Height",'t1rowheight',60,0,600,1,10],

		'ff0' => ['l',"Debug Options",'Debug'],
		'ff1' => ['c',"Colored terminal output",'termcolors'],
	);
	return %opts;
}
print ".";

sub getTableWidths {
	my @list = ((FIO::config('Table','t1c0') or 20));
	push(@list,(FIO::config('Table','t1c1') or 140));
	push(@list,(FIO::config('Table','t1c2') or 100));
	push(@list,(FIO::config('Table','t1c3') or 53));
	push(@list,(FIO::config('Table','t1c4') or 0));
	push(@list,(FIO::config('Table','t1c5') or 0));
	push(@list,(FIO::config('Table','t1c6') or 0));
	return @list;
}
print ".";

sub getDefaults {
	return (
		['Main','partyfn','party.xml'],
		['Main','highinitfirst',1],
		['Main','savepos',1],
		['UI','notabs',1],
		['UI','waittoskip',1],
		['Font','bigent',"Verdana 24"],
	);
}
print ".";

print "OK; ";
1;
