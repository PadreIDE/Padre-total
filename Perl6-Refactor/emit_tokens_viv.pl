# The start of a gimme5 replacement based on STD parsing.
# viv stands for roman numbers VIV (i.e. Perl 5 to 6)
use strict;
use 5.010;
use warnings;
use lib 'lib';
use Carp;
use STD;
use utf8;
use YAML::XS;

my $OPT_log = 0;
my $OPT_find_declaration = undef;
my $OPT_rename_variable  = undef;
my $OPT_color = 0;
our $PACKAGE_TYPE = '';
our $SCOPE = '';
our @TOKEN_TABLE = ();

my @context;

sub USAGE {
	print <<'END';
viv [switches] filename
where switches can be:
	--log                              Emit debugging info to standard error
	--help                             Prints this help
	--find-declaration=Name,Line       Find variable declaration's
	--rename-var=OldName,Line,NewNew   Rename all instances of a variable
	--color                            Coloring time... :)
END
	exit;
}

sub MAIN {
	USAGE unless @_;

	require Getopt::Long;
	my $help = 0;
	Getopt::Long::GetOptions(
		'log',                 =>\$OPT_log,
		'color',               =>\$OPT_color,
		'find-declaration=s'   => \$OPT_find_declaration,
		'rename-var=s',        => \$OPT_rename_variable,
		'help'                 =>\$help,
	);
	
	if($help) {
		USAGE;
	}

	
	my $variable = '';
	my $line_number = '';
	my $new_variable = '';
	if(defined $OPT_find_declaration && $OPT_find_declaration =~ /^(.+?)\s*,\s*(\d+)$/) {
		($variable, $line_number) = ($1, $2);
	} else {
		$OPT_find_declaration = undef;
	}
	
	if(defined $OPT_rename_variable && $OPT_rename_variable =~ /^(.+?)\s*,\s*(\d+)\s*,\s*(.+?)$/) {
		($variable, $line_number, $new_variable) = ($1, $2, $3);
	} else {
		$OPT_rename_variable = undef;
	}

	my $filename = shift @ARGV;
	my $r;
	if ( $filename and -f $filename ) {
		$r = STD->parsefile( $filename, actions => 'Actions' )->{'_ast'};
	} else {
		print "no filename\n\n";
		USAGE;
	}
	delete $r->{CORE};
	delete $r->{MATCH}{CORE};
	$r->ret( $r->emit_token(0) );

	dump_token_table();
	
	if($OPT_find_declaration) {
		show_find_variable_declaration($variable, $line_number, $filename);
	}
	
	if($OPT_rename_variable) {
		show_rename_variable($variable, $line_number, $new_variable, $filename);
	}
	
	if($OPT_color) {
		#XXX -  should experiment with color information
		#       from token table 
		
		my $text = _slurp($filename);
		my %colors = (
			'DeclareVar'     => 'blue',
			'DeclareRoutine' => 'blue',
			'FlowControl'    => 'blue',
			'Module'         => 'blue',
			'Variable'       => 'red',
			'Parameter'      => 'red',
			'VariableName'	 => 'red',
			'MethodName'     => 'red',
			'SubName'        => 'red',
			'GrammarName'    => 'red',
		);
		my $buffer = '';
		my $last_color = '';
		for(my $i = 0; $i < length $text; $i++) {
			my $c = substr $text, $i, 1;
			
			my $token_to_color = undef;
			foreach my $token (@TOKEN_TABLE) {
				my $from = $token->{from};
				my $token_length = length $token->{name};
				if($i >= $from && ($i <= $from + $token_length)) {
					$token_to_color = $token;
					last;
				}			
			}
			if($token_to_color) {
				my $type = $token_to_color->{type};
				if($type) {
					my $color = $colors{$type};
					if($color && $color ne $last_color) {
						if(length $last_color) {
							$buffer .= "</$last_color>";
						}
						$buffer .= "<$color>"; 
						$last_color = $color;
					} 
				}
			}
			
			$buffer .= $c;
		}
		if(length $last_color) {
			$buffer .= "</$last_color>";
		}
		
		print $buffer;
	}
}

#-----------------------------------------------------
# Load file into a scalar without File::Slurp
# see perlfaq5
#-----------------------------------------------------
sub _slurp {
    my $filename = shift;
    my $fh = IO::File->new($filename)
        or croak "Could not open $filename for reading";
    local $/ = undef;   #enable localized slurp mode
    my $contents = <$fh>;
    close $fh
        or croak "Could not close $filename";
    return $contents;
}

#
# Shows the variable declaration..
#
sub show_find_variable_declaration {
	my ($variable, $line_number, $filename) = @_;

	my ($found_symbol_index, @variables) = find_variable_declaration($variable, $line_number);
	if($found_symbol_index != -1) {
		my $symbol = $TOKEN_TABLE[$found_symbol_index];
		printf "Found declaration at line %d.\n", $symbol->{line};

		open FH, $filename or die "cannot open $filename\n";
		my $count = 1;
		print "...\n";
		while(my $line = <FH>) {
			chomp $line;
			if($count == $symbol->{line} || 
				($count == $line_number) ) 
			{
				print "#$count: " . $line . "\n...\n";
			} 
			$count++;
		}
		close FH;

	} else {
		print "No declaration found... is that correct?\n";
	}

}

#
# rename variable by first finding a variable declaration's
# and then finding all variables for that declaration within the 
# same/upper lexical scope.
#
sub show_rename_variable {
	my ($variable, $line_number, $new_variable, $filename) = @_;

	my ($found_symbol_index, @variables) = find_variable_declaration($variable, $line_number);
	if($found_symbol_index != -1) {
		my $symbol = $TOKEN_TABLE[$found_symbol_index];
		printf "Found declaration at line %d.\n", $symbol->{line};

		open FH, $filename or die "cannot open $filename\n";
		my $count = 1;
		my $pos = 0;
		$| = 1;
		print "\n";
		while(my $line = <FH>) {
			my $len = length $line;
			chomp $line;
			foreach my $var (@variables) {
				if($count == $var->{line}) {
					print "#$count: " . $line . "\n  -->\n";
					substr $line, $var->{from} - $pos, $var->{to} - $var->{from}, $new_variable;
					print "#$count: " . $line . "\n...\n\n";
					last;
				}
			}
			if( $count == $line_number ) 
			{
				print "#$count: " . $line . "\n-->\n";
				substr $line, $symbol->{from} - $pos, $symbol->{to} - $symbol->{from}, $new_variable;
				print "#$count: " . $line . "\n...\n\n";
			} 
			$pos += $len;
			$count++;
		}
		close FH;

	} else {
		print "No declaration found... is that correct?\n";
	}

}

sub find_token_at {
	my ($variable, $line_number) = @_;

	my ($position,$scope) = (-1, '');
	for(my $i = 0; $i < scalar @TOKEN_TABLE; $i++ ) {
		my $symbol = $TOKEN_TABLE[$i];
		if( $symbol->{line} == $line_number && 
			$symbol->{name} eq $variable) 
		{
			$position = $i;
			$scope = $symbol->{scope};
			last;
		}
	}
	
	return ($position, $scope);
}

#
# Finds a variable's declaration by poking around in the VIV token table
#
sub find_variable_declaration {
	my ($variable, $line_number) = @_;

	my ($symbol_position, $symbol_scope) = find_token_at($variable, $line_number);
	
	my $declaration_position = -1;
	my @variables = ();
	if($symbol_position == -1) {
		#Didnt find what you needed
		print "Did not find any variable named '$variable' at line $line_number\n";
	} else {
		# Try to find its declaration
		for(my $i = $symbol_position; $i >= 0; $i--) {
			my $symbol = $TOKEN_TABLE[$i];
			my $type = $symbol->{type};
			if($symbol->{name} eq $variable && 
					($type eq 'VariableName' || $type eq 'Parameter') &&
					(length $symbol_scope) >= (length $symbol->{scope}) )
			{
				$declaration_position = $i;
				last;
			}
		}
		
		if($declaration_position != -1) {
			for(my $i = $declaration_position; $i < scalar @TOKEN_TABLE; $i++) {
				my $symbol = $TOKEN_TABLE[$i];
				my $type = $symbol->{type};
				if($symbol->{name} eq $variable &&
					$type eq 'Variable' &&
						(length $symbol_scope) >= (length $symbol->{scope}))
				{
					print "found " . $symbol->{name} . " at " . $symbol->{line} . "\n";
					push @variables, $symbol;
				}
			}
		}
	}
	
	return ($declaration_position, @variables);
}

sub dump_token_table {
	my $separator = '-' x 76;
	print "\n" . $separator . "\n";		
	my $format = "| %-15s | %-15s | %-20s | %-4s |\n";
	printf $format, 'NAME', 'TYPE', 'SCOPE', 'LINE';
	print $separator . "\n";
	foreach my $symbol ( @TOKEN_TABLE ) {
		printf $format, 
			$symbol->{name},
			$symbol->{type},
			$symbol->{scope},
			$symbol->{line};
	}
	print $separator . "\n\n";
	
	return;
}
###################################################################

{

	package Actions;

	# Generic ast translation done via autoload

	our $AUTOLOAD;
	my $SEQ = 1;

	sub AUTOLOAD {
		my $self  = shift;
		my $match = shift;
		return if @_;    # not interested in tagged reductions
		return
		  if $match->{_ast}{_specific} and ref( $match->{_ast} ) =~ /^VAST/;
		my $r = hoistast($match);
		( my $class = $AUTOLOAD ) =~ s/^Actions/VAST/;
		$class =~ s/__S_\d\d\d/__S_/ and $r->{_specific} = 1;
		gen_class($class);
		bless $r, $class unless ref($r) =~ /^VAST/;
		$match->{'_ast'} = $r;
	}

	# propagate ->{'_ast'} nodes upward
	# (untransformed STD nodes in output indicate bugs)

	sub hoistast {
		my $node = shift;
		my $text = $node->Str;
		my %r;
		my @all;
		my @fake;
		for my $k ( keys %$node ) {

			my $v = $node->{$k};
			if ( $k eq 'O' ) {
				for my $key ( keys %$v ) {
					$r{$key} = $$v{$key};
				}
			}
			elsif ( $k eq 'PRE' ) {
			}
			elsif ( $k eq 'POST' ) {
			}
			elsif ( $k eq 'SIGIL' ) {
				$r{SIGIL} = $v;
			}
			elsif ( $k eq 'sym' ) {
				if ( ref $v ) {
					if ( ref($v) eq 'ARRAY' ) {
						$r{SYM} = ::Dump($v);
					}
					elsif ( ref($v) eq 'HASH' ) {
						$r{SYM} = ::Dump($v);
					}
					elsif ( $v->{_pos} ) {
						$r{SYM} = $v->Str;
					}
					else {
						$r{SYM} = $v->TEXT;
					}
				}
				else {
					$r{SYM} = $v;
				}
			}
			elsif ( $k eq '_arity' ) {
				$r{ARITY} = $v;
			}
			elsif ( $k eq '~CAPS' ) {

				if ( ref $v ) {
					for (@$v) {
						next unless ref $_;    # XXX skip keys?
						push @all, $_->{'_ast'};
					}
				}
			}
			elsif ( $k eq '_from' ) {
				$r{BEG} = $v;
				$r{END} = $node->{_pos};
				if ( exists $::MEMOS[$v]{'ws'} ) {
					my $wsstart = $::MEMOS[$v]{'ws'};
					$r{WS} = $v - $wsstart
					  if defined $wsstart and $wsstart < $v;
				}
			}
			elsif ( $k =~ /^[a-zA-Z]/ ) {
				if ( $k eq 'noun' ) {    # trim off PRE and POST
					$r{BEG} = $v->{_from};
					$r{END} = $v->{_pos};
				}
				if ( ref($v) eq 'ARRAY' ) {
					my $zyg = [];
					for my $z (@$v) {
						if ( ref $z ) {
							if ( ref($z) eq 'ARRAY' ) {
								push @$zyg, $z;
								push @fake, @$z;
							}
							elsif ( exists $z->{'_ast'} ) {
								my $zy = $z->{'_ast'};
								push @fake, $zy;
								push @$zyg, $zy;
							}
						}
						else {
							push @$zyg, $z;
						}
					}
					$r{$k} = $zyg;

					#		    $r{zygs}{$k} = $SEQ++ if @$zyg and $k ne 'sym';
				}
				elsif ( ref $v ) {
					if ( exists $v->{'_ast'} ) {
						push @fake, $v->{'_ast'};
						$r{$k} = $v->{'_ast'};
					}
					else {
						$r{$k} = $v;
					}

					#		    $r{zygs}{$k} = $SEQ++;
					unless ( ref( $r{$k} ) =~ /^VAST/ ) {
						my $class = "VAST::$k";
						gen_class($class);
						bless $r{$k}, $class unless ref( $r{$k} ) =~ /^VAST/;
					}
				}
				else {
					$r{$k} = $v;
				}
			}
		}
		if ( @all == 1 and defined $all[0] ) {
			$r{'.'} = $all[0];
		}
		elsif (@all) {
			$r{'.'} = \@all;
		}
		elsif (@fake) {
			$r{'.'} = \@fake;
		}
		else {
			$r{TEXT} = $text;
		}
		\%r;
	}

	sub hoist {
		my $match = shift;

		my %r;
		my $v = $match->{O};
		if ($v) {
			for my $key ( keys %$v ) {
				$r{$key} = $$v{$key};
			}
		}
		if ( $match->{sym} ) {

			#    $r{sym} = $match->{sym};
		}
		if ( $match->{ADV} ) {
			$r{ADV} = $match->{ADV};
		}
	}

	sub CHAIN {
		my $self  = shift;
		my $match = shift;
		my $r     = hoistast($match);

		my $class = $match->{O}{kind} // $match->{sym} // 'termish';
		$class =~ s/^STD:://;
		$class =~ s/^/VAST::/;

		gen_class($class);
		$r = bless $r, $class;
		$match->{'_ast'} = $r;
	}

	sub LIST {
		my $self  = shift;
		my $match = shift;
		my $r     = hoist($match);

		my @list   = @{ $match->{list} };
		my @delims = @{ $match->{delims} };
		my @all;
		while (@delims) {
			my $term = shift @list;
			push @all, $term->{_ast};
			my $infix = shift @delims;
			push @all, $infix->{_ast};
		}
		push @all, $list[0]->{_ast} if @list;
		pop @all while @all and not $all[-1]{END};
		$r->{BEG} = $all[0]{BEG};
		$r->{END} = $all[-1]{END} // $r->{BEG};
		$r->{'.'} = \@all;

		my $class = $match->{O}{kind} // $match->{sym} // 'termish';
		$class =~ s/^STD:://;
		$class =~ s/^/VAST::/;
		gen_class($class);
		$r = bless $r, $class;
		$match->{'_ast'} = $r;
	}

	sub POSTFIX {
		my $self  = shift;
		my $match = shift;
		my $r     = hoist($match);
		my $a     = $r->{'.'} = [ $match->{arg}->{_ast}, $match->{_ast} ];
		$r->{BEG} = $a->[0]->{BEG}  // $match->{_from};
		$r->{END} = $a->[-1]->{END} // $match->{_pos};

		my $class = $match->{O}{kind} // $match->{sym} // 'termish';
		$class =~ s/^STD:://;
		$class =~ s/^/VAST::/;
		gen_class($class);
		$r = bless $r, $class;
		$match->{'_ast'} = $r;
	}

	sub PREFIX {
		my $self  = shift;
		my $match = shift;
		my $r     = hoist($match);
		my $a     = $r->{'.'} = [ $match->{_ast}, $match->{arg}->{_ast} ];

		$r->{BEG} = $a->[0]->{BEG}  // $match->{_from};
		$r->{END} = $a->[-1]->{END} // $match->{_pos};

		my $class = $match->{O}{kind} // $match->{sym} // 'termish';
		$class =~ s/^STD:://;
		$class =~ s/^/VAST::/;
		gen_class($class);
		$r = bless $r, $class;
		$match->{'_ast'} = $r;
	}

	sub INFIX {
		my $self  = shift;
		my $match = shift;
		my $r     = hoist($match);
		my $a     = $r->{'.'} =
		  [ $match->{left}->{_ast}, $match->{_ast}, $match->{right}->{_ast} ];
		$r->{BEG} = $a->[0]->{BEG}  // $match->{_from};
		$r->{END} = $a->[-1]->{END} // $match->{_pos};

		my $class = $match->{O}{kind} // $match->{sym} // 'termish';
		$class =~ s/^STD:://;
		$class =~ s/^/VAST::/;
		gen_class($class);
		$r = bless $r, $class;
		$match->{'_ast'} = $r;
	}

	sub EXPR {
		return;
	}

	sub gen_class {
		my $class = shift;

		# say $class;
		no strict 'refs';
		if ( @{ $class . '::ISA' } ) {
			print STDERR "Existing class $class\n" if $OPT_log;
			return;
		}
		print STDERR "Creating class $class\n" if $OPT_log;
		@{ $class . '::ISA' } = 'VAST::Base';
	}

}

###################################################################

{

	package VAST::Base;

	sub ret {
		my $self = shift;
		my $val  = join '', @_;
		my @c    = map { ref $_ } @context;
		my $c    = "@c " . ref($self);
		$c =~ s/VAST:://g;
		print STDERR "$c returns $val\n" if $OPT_log;

		wantarray ? @_ : $val;
	}

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @text;
		$context[$lvl] = $self;

		if ( exists $self->{'.'} ) {
			my $last = $self->{BEG};
			my $all  = $self->{'.'};
			my @kids;
			for my $kid ( ref($all) eq 'ARRAY' ? @$all : $all ) {
				next unless $kid;
				if ( not defined $kid->{BEG} ) {
					$kid->{BEG} = $kid->{_from} // next;
					$kid->{END} = $kid->{_pos};
				}
				push @kids, $kid;
			}
			for my $kid ( sort { $a->{BEG} <=> $b->{BEG} } @kids ) {
				my $kb = $kid->{BEG};
				if ( $kb > $last ) {
					push @text, substr( $::ORIG, $last, $kb - $last );
				}
				if ( ref($kid) eq 'HASH' ) {
					print STDERR ::Dump($self);
				}
				push @text, scalar $kid->emit_token( $lvl + 1 );
				$last = $kid->{END};

			}
			my $se = $self->{END};
			if ( $se > $last ) {
				push @text, substr( $::ORIG, $last, $se - $last );
			}
		}
		else {

			push @text, $self->{TEXT};
		}
		
		splice( @context, $lvl );
		$self->ret(@text);
	}
	
	sub add_token {
		my ( $self, $name, $type ) = @_;
		$name =~ s/^\s+|\s+$//g;
		my $from = $self->{BEG};
		my $to = $self->{END};
		my $line = STD->lineof($from);
		push @TOKEN_TABLE, {
			name  => $name,
			type  => $type,
			line  => $line,
			from  => $from,
			to    => $to,
			scope => $SCOPE,
		}; 
	}

}

{ package VAST::TEXT; our @ISA = 'VAST::Base'; }

{

	package VAST::Additive;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::ADVERB;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::apostrophe;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::arglist;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::args;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::assertion;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::assertion__S_Bang;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::assertion__S_Bra;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::assertion__S_Cur_Ly;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::assertion__S_DotDotDot;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::assertion__S_method;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::assertion__S_name;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::assertion__S_Question;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::atom;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Autoincrement;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::babble;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_Back;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_d;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_h;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_misc;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_n;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_s;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_stopper;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_t;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_v;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_w;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::backslash__S_x;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::before;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::block;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::blockoid;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::capterm;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::cclass_elem;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::circumfix;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::circumfix__S_Bra_Ket;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::circumfix__S_Cur_Ly;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::circumfix__S_Paren_Thesis;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::circumfix__S_sigil;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::codeblock;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::colonpair;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Comma;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::comp_unit;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		$context[$lvl] = $self;

		my $r = $self->ret( $self->{statementlist}->emit_token( $lvl + 1 ) );
		splice( @context, $lvl );

		$r;
	}
}

{

	package VAST::Concatenation;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Conditional;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::CORE;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::declarator;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::default_value;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::deflongname;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::def_module_name;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::desigilname;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::dotty;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::dotty__S_Dot;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::dottyop;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::eat_terminator;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::escape;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::escape__S_At;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::escape__S_Back;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::escape__S_Dollar;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::EXPR;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::fatarrow;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::fulltypename;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::hexint;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::ident;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::identifier;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::index;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_and;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_BangEqual;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_ColonEqual;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_Comma;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_DotDot;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_eq;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_Equal;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_EqualEqual;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_EqualGt;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_gt;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_Gt;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infixish;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_le;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_lt;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_Lt;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_LtEqual;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_Minus;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_ne;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_or;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_orelse;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_Plus;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_PlusAmp;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_PlusVert;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix_postfix_meta_operator;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix_postfix_meta_operator__S_Equal;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_QuestionQuestion_BangBang;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_SlashSlash;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_Star;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infixstopper;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_Tilde;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_TildeTilde;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_TildeVert;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_VertVert;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::infix__S_x;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::integer;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Item_assignment;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Junctive_or;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::label;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::lambda;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::left;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::List_assignment;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::litchar;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::longname;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Loose_and;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Loose_or;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Loose_unary;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Back;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Bra_Ket;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Caret;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_CaretCaret;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_ColonColon;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_ColonColonColon;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Cur_Ly;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Dollar;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_DollarDollar;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Dot;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Double_Double;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Lt_Gt;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_mod;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Nch;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Paren_Thesis;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_qw;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_sigwhite;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_Single_Single;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::metachar__S_var;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::method_def;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my $OLD_SCOPE = $SCOPE;
		$SCOPE .= ':' . $PACKAGE_TYPE;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$SCOPE = $OLD_SCOPE;
		$self->add_token( $t[1], 'MethodName' );
		$self->ret(@t);
	}
}

{

	package VAST::routine_declarator__S_sub;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my $OLD_SCOPE = $SCOPE;
		$SCOPE .= ':' . $self->{SYM};
		$self->add_token( $self->{SYM}, 'DeclareRoutine');
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$SCOPE = $OLD_SCOPE;
		$self->ret(@t);
	}
}

{

	package VAST::routine_def;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token( $t[1], 'SubName' );
		$self->ret(@t);
	}
}

{

	package VAST::Methodcall;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token($t[0], 'MethodCall');
		$self->ret(@t);
	}
}

{

	package VAST::methodop;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token($t[0], 'MethodOp');
		$self->ret(@t);
	}
}

{

	package VAST::modifier_expr;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::mod_internal;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::mod_internal__S_adv;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::mod_internal__S_ColonBangs;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::mod_internal__S_Coloni;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::mod_internal__S_Colonmy;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::mod_internal__S_Colons;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::module_name;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::module_name__S_normal;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::morename;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::multi_declarator;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::multi_declarator__S_multi;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::multi_declarator__S_null;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::multi_declarator__S_proto;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Multiplicative;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::multisig;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::name;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::named_param;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Named_unary;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::nibbler;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::nofun;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Nonchaining;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::normspace;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;

		my @t = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_capterm;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_circumfix;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_colonpair;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_fatarrow;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_multi_declarator;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_package_declarator;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_regex_declarator;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_routine_declarator;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_scope_declarator;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_statement_prefix;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_term;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_value;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::noun__S_variable;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token( $t[0], 'Variable' );
		$self->ret(@t);
	}
}

{

	package VAST::nulltermish;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::number;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::number__S_numish;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::numish;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::opener;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::package_declarator;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::package_declarator__S_class;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my $OLD_PACKAGE_TYPE = $PACKAGE_TYPE;
		$PACKAGE_TYPE = $self->{SYM};
		$self->add_token( $PACKAGE_TYPE, 'Module' );
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$PACKAGE_TYPE = $OLD_PACKAGE_TYPE;
		$self->ret(@t);
	}
}

{

	package VAST::package_declarator__S_grammar;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		$PACKAGE_TYPE = $self->{SYM};
		$self->add_token( $PACKAGE_TYPE, 'Module' );
		my @t    = $self->SUPER::emit_token( $lvl + 1, $self->{SYM} );
		$self->ret(@t);
	}
}

{

	package VAST::package_declarator__S_role;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		$PACKAGE_TYPE = $self->{SYM};
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::package_declarator__S_package;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		$PACKAGE_TYPE = $self->{SYM};
		$self->add_token( $PACKAGE_TYPE, 'Module' );
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::package_declarator__S_module;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		$PACKAGE_TYPE = $self->{SYM};
		$self->add_token( $PACKAGE_TYPE, 'Module' );
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::package_declarator__S_slang;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		$PACKAGE_TYPE = $self->{SYM};
		$self->add_token( $PACKAGE_TYPE, 'Module' );
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::package_def;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my $OLD_SCOPE = $SCOPE;
		$SCOPE .= ':' . $PACKAGE_TYPE;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$SCOPE = $OLD_SCOPE;
		
		$PACKAGE_TYPE =~ s/class/ClassName/;
		$PACKAGE_TYPE =~ s/slang/SlangName/;
		$PACKAGE_TYPE =~ s/package/PackageName/;
		$PACKAGE_TYPE =~ s/module/ModuleName/;
		$PACKAGE_TYPE =~ s/role/RoleName/;
		$PACKAGE_TYPE =~ s/grammar/GrammarName/;

		$self->add_token( $t[1], $PACKAGE_TYPE );
		$self->ret(@t);
	}
}

{

	package VAST::parameter;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token( $t[0], 'Parameter' );
		$self->ret(@t);
	}
}

{

	package VAST::param_sep;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::param_var;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::pblock;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my $OLD_SCOPE = $SCOPE;
		$SCOPE .= ':' . 'pblock';
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$SCOPE = $OLD_SCOPE;
		$self->ret(@t);
	}
}

{

	package VAST::pod_comment;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::POST;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postcircumfix;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postcircumfix__S_Bra_Ket;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postcircumfix__S_Cur_Ly;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postcircumfix__S_Fre_Nch;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postcircumfix__S_Lt_Gt;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postcircumfix__S_Paren_Thesis;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postfix;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postfix__S_MinusMinus;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postfix__S_PlusPlus;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postfix_prefix_meta_operator;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postfix_prefix_meta_operator__S_Nch;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::postop;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::PRE;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::prefix;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::prefix__S_Bang;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::prefix__S_Minus;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::prefix__S_not;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::prefix__S_Plus;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::prefix__S_temp;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quantified_atom;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quantifier;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quantifier__S_Plus;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quantifier__S_Question;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quantifier__S_Star;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quantifier__S_StarStar;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quantmod;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quibble;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quote;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quote__S_Double_Double;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quote__S_Fre_Nch;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quote__S_Lt_Gt;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quotepair;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quote__S_s;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quote__S_Single_Single;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::quote__S_Slash_Slash;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::regex_block;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::regex_declarator;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::regex_declarator__S_regex;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		$self->add_token( $self->{SYM}, 'DeclareRoutine');
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::regex_declarator__S_rule;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		$self->add_token( $self->{SYM}, 'DeclareRoutine');
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::regex_declarator__S_token;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		$self->add_token( $self->{SYM}, 'DeclareRoutine');		
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::regex_def;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Replication;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::right;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::routine_declarator;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::routine_declarator__S_method;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self    = shift;
		my $lvl     = shift;
		my $OLD_PACKAGE_TYPE = $PACKAGE_TYPE;
		$PACKAGE_TYPE = $self->{SYM};
		$self->add_token( $self->{SYM}, 'DeclareRoutine' );
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$PACKAGE_TYPE = $OLD_PACKAGE_TYPE;
		$self->ret(@t);
	}
}

{

	package VAST::rxinfix;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::rxinfix__S_Tilde;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::rxinfix__S_Vert;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::rxinfix__S_VertVert;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::scoped;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::scope_declarator;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::scope_declarator__S_constant;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token( $t[1], 'constant' );
		$self->ret(@t);
	}
}

{

	package VAST::scope_declarator__S_has;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my $symbol = $self->{SYM};
		$self->add_token( $self->{SYM}, 'DeclareVar' );
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token( $t[1], "VariableName" );
		$self->ret(@t);
	}
}

{

	package VAST::scope_declarator__S_my;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my $symbol = $self->{SYM};
		$self->add_token( $symbol, 'DeclareVar' );
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token( $t[1], "VariableName" );
		$self->ret(@t);
	}
}

{

	package VAST::scope_declarator__S_our;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my $symbol = $self->{SYM};
		$self->add_token( $symbol, 'DeclareVar' );
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token( $t[1], "VariableName" );
		$self->ret(@t);
	}
}

{

	package VAST::semiarglist;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::semilist;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::sibble;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::sigil;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::sigil__S_Amp;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::sigil__S_At;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::sigil__S_Dollar;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::sigil__S_Percent;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::sign;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::signature;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::spacey;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::special_variable;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::special_variable__S_Dollar_a2_;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::special_variable__S_DollarSlash;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_control;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_control__S_default;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token( $self->{SYM}, 'FlowControl' );
		$self->ret(@t);
	}
}

{

	package VAST::statement_control__S_for;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		$self->add_token( $self->{SYM}, 'FlowControl' );
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_control__S_given;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		$self->add_token( $self->{SYM}, 'FlowControl' );
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_control__S_if;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		$self->add_token( $self->{SYM}, 'FlowControl' );
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_control__S_loop;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		$self->add_token( $self->{SYM}, 'FlowControl' );
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_control__S_when;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		$self->add_token( $self->{SYM}, 'FlowControl' );
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_control__S_while;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		$self->add_token( $self->{SYM}, 'FlowControl' );
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statementlist;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_mod_cond;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_mod_cond__S_if;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token($self->{SYM}, 'FlowControl');
		$self->ret(@t);
	}
}

{

	package VAST::statement_mod_cond__S_unless;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token($self->{SYM}, 'FlowControl');
		$self->ret(@t);
	}
}

{

	package VAST::statement_control__S_unless;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token($self->{SYM}, 'FlowControl');
		$self->ret(@t);
	}
}

{

	package VAST::statement_mod_loop;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token($self->{SYM}, 'FlowControl');
		$self->ret(@t);
	}
}

{

	package VAST::statement_mod_loop__S_for;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token($self->{SYM}, 'FlowControl');
		$self->ret(@t);
	}
}

{

	package VAST::statement_mod_loop__S_while;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token($self->{SYM}, 'FlowControl');
		$self->ret(@t);
	}
}

{

	package VAST::statement_prefix;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::statement_prefix__S_do;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token($self->{SYM}, 'FlowControl');
		$self->ret(@t);
	}
}

{

	package VAST::statement_prefix__S_try;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token($self->{SYM}, 'Exception');
		$self->ret(@t);
	}
}

{

	package VAST::stdstopper;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::stopper;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::sublongname;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::subshortname;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Symbolic_unary;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::term__S_identifier;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::terminator;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret('');
	}
}

{ package VAST::terminator__S_BangBang; our @ISA = 'VAST::terminator'; }

{ package VAST::terminator__S_for; our @ISA = 'VAST::terminator'; }

{ package VAST::terminator__S_if; our @ISA = 'VAST::terminator'; }

{ package VAST::terminator__S_Ket; our @ISA = 'VAST::terminator'; }

{ package VAST::terminator__S_Ly; our @ISA = 'VAST::terminator'; }

{ package VAST::terminator__S_Semi; our @ISA = 'VAST::terminator'; }

{ package VAST::terminator__S_Thesis; our @ISA = 'VAST::terminator'; }

{ package VAST::terminator__S_unless; our @ISA = 'VAST::terminator'; }

{ package VAST::terminator__S_while; our @ISA = 'VAST::terminator'; }

{ package VAST::terminator__S_when; our @ISA = 'VAST::terminator'; }

{

	package VAST::termish;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::term;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::term__S_name;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::term__S_self;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		$self->add_token( $self->{SYM}, 'p6Variable' );
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::term__S_Star;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::term__S_undef;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::Tight_or;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::trait;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::trait_auxiliary;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::trait_auxiliary__S_does;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token($self->{SYM}, 'Trait');
		$self->ret(@t);
	}
}

{

	package VAST::trait_auxiliary__S_is;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token($self->{SYM}, 'Trait');
		$self->ret(@t);
	}
}

{

	package VAST::trait_mod__S_does;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token($self->{SYM}, 'Trait');
		$self->ret(@t);
	}
}

{

	package VAST::trait_mod__S_is;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token($self->{SYM}, 'Trait');
		$self->ret(@t);
	}
}

{

	package VAST::twigil;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::twigil__S_Dot;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::twigil__S_Star;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::type_constraint;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::typename;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret('');
	}
}

{

	package VAST::unitstopper;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::unspacey;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::unv;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::val;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::value;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::value__S_number;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token($t[0], 'Number');
		$self->ret(@t);
	}
}

{

	package VAST::value__S_quote;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::variable;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::variable_declarator;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::vws;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::comment__S_Sharp;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->add_token( $t[0], 'Comment' );
		$self->ret(@t);
	}
}

{

	package VAST::ws;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{
	package VAST::statement_control__S_use;
	our @ISA = 'VAST::Base';
	
	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::xblock;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

{

	package VAST::XXX;
	our @ISA = 'VAST::Base';

	sub emit_token {
		my $self = shift;
		my $lvl  = shift;
		my @t    = $self->SUPER::emit_token( $lvl + 1 );
		$self->ret(@t);
	}
}

if ( $0 eq __FILE__ ) {
	::MAIN(@ARGV);
}
