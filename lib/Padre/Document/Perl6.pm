package Padre::Document::Perl6;

use 5.010;
use strict;
use warnings;
use English '-no_match_vars';  # Avoids regex performance penalty
use Padre::Document ();
use Padre::Task::Perl6 ();
use File::Which;

our $VERSION = '0.36';
our @ISA     = 'Padre::Document';

# max lines to display in a calltip
my $CALLTIP_DISPLAY_COUNT = 10;

# used for coloring by parrot
my %perl6_colors = (
	quote_expression => Px::PADRE_BLUE,
	parse            => undef,
	statement_block  => undef,
	statementlist    => undef,
	statement        => undef,
	expr             => undef,
	'term:'          => undef,
	noun             => undef,
	value => undef,
	quote => undef,
	quote_concat => undef,
	quote_term => undef,
	quote_literal => undef,
	post => Px::PADRE_MAGENTA,
	dotty => undef,
	dottyop => undef,
	methodop => Px::PADRE_GREEN,
	name => Px::PADRE_GREEN,
	identifier => undef,
	term => undef,
	args => undef,
	arglist => undef,
	EXPR => undef,
	statement_control => undef,
	use_statement => undef,
	sym => Px::PADRE_RED,
	'infix:='  => Px::PADRE_GREEN,
	'infix:+'  => Px::PADRE_GREEN,
#   'infix:*'  => Px::PADRE_GREEN,
#	'infix:/'  => Px::PADRE_GREEN,
	'infix:,'  => Px::PADRE_GREEN,
	'infix:..' => undef,
	'prefix:=' => undef,
	'infix:|' => undef,
	'infix:==' => undef,
	'infix:*=' => undef,
	twigil => undef,
	if_statement => undef,
	'infix:eq' => undef,
	semilist => undef,
	scope_declarator => undef,
	scoped => undef,
	variable_declarator => undef,
	declarator => undef,
	variable => Px::PADRE_RED, #Px::PADRE_DIM_GRAY,
	integer => undef,
	number => Px::PADRE_BROWN,
	circumfix => undef,
	param_sep => undef,
	sigil => undef,
	desigilname => undef,
	longname => undef,
	parameter => undef,
	param_var => undef,
	quant => undef,
	pblock => undef,
	block => undef,
	signature => undef,
	for_statement => undef,
	xblock => undef,
	lambda => Px::PADRE_GREEN,
);

#    'regex_block' => Px::PADRE_BLACK,
#    'number' => Px::PADRE_ORANGE,
#    'param_var' => Px::PADRE_CRIMSON,
#    '_hash' => Px::PADRE_ORANGE,


sub text_with_one_nl {
    my $self = shift;
    my $text = $self->text_get;
    my $nlchar = "\n";
    if ( $self->get_newline_type eq 'WIN' ) {
        $nlchar = "\r\n";
    }
    elsif ( $self->get_newline_type eq 'MAC' ) {
        $nlchar = "\r";
    }
    $text =~ s/$nlchar/\n/g;
    return $text;
}

# a SLOW WAY to parse and colorize perl6 files
sub colorize {
    my $self = shift;
    
    # temporary overlay using the parse tree given by parrot
    # TODO: let the user select which one to use
    # TODO: but the parrot parser in the background
	#my $perl6 = $self->get_perl6;
	#if ($perl6) {
	#	$self->_parrot_color($perl6);
	#	return;
	#}

    my $config = Padre::Plugin::Perl6::plugin_config;
    if($config->{p6_highlight} || $self->{force_p6_highlight}) {
        # Create a coloring task and hand off to the task manager
        my $task = Padre::Task::Perl6->new(
            text => $self->text_with_one_nl,
            editor => $self->editor,
            document => $self);
        $task->schedule();
    }
}

sub _parrot_color {
	my ($self, $perl6) = @_;
	
	my $editor = $self->editor;

	use File::Temp qw(tempdir);
	my $dir = tempdir(CLEANUP => 1);
	my $file = "$dir/file";

	if (open my $fh, '>', $file) {
		print $fh $self->text_get;
	}	

	my @data = `"$perl6" --target=parse --dumper=padre "$file"`;
	chomp @data;
	my @pd;
	foreach my $line (@data) {
		$line =~ s/^\s+//;
		my ($start, $length, $type, $str) = split /\s+/, $line, 4;
		push @pd, {
			start => $start,
			length => $length,
			type => $type,
			str => $str,
			};
		if (not exists ($perl6_colors{$type})) {
			warn "No Perl6 color definiton for '$type':  $str\n";
			next;
		}
		next if not defined $perl6_colors{$type}; # no need to color
		my $color = $perl6_colors{$type};
		$editor->StartStyling($start, $color);
        $editor->SetStyling($length, $color);

	}
	$self->{_parse_tree} = \@pd;

	#use Data::Dumper;
	#print Dumper \@data;

	return;
}

sub get_perl6 {
    my $self     = shift;

	my $exe_name = $^O eq 'MSWin32' ? 'perl6.exe' : 'perl6';
	my $perl6 = File::Which::which($exe_name);
	if (not $perl6) {
		if (not $ENV{RAKUDO_DIR}) {
			my $main = Padre->ide->wx->main;
			$main->error("Either $exe_name needs to be in the PATH or RAKUDO_DIR must point to the directory of the Rakudo checkout.");
		}
		$perl6 = File::Spec->catfile($ENV{RAKUDO_DIR}, $exe_name);
	}

	return $perl6;
}

sub get_command {
    my $self     = shift;

    my $filename = $self->filename;
	my $perl6    = $self->get_perl6;

    return qq{"$perl6" "$filename"};
}

# Checks the syntax of a Perl document.
# Documented in Padre::Document!
# Implemented as a task. See Padre::Task::SyntaxChecker::Perl6
sub check_syntax {
    my $self  = shift;
    my %args  = @ARG;
    $args{background} = 0;
    return $self->_check_syntax_internals(\%args);
}

sub check_syntax_in_background {
    my $self  = shift;
    my %args  = @ARG;
    $args{background} = 1;
    return $self->_check_syntax_internals(\%args);
}

sub _check_syntax_internals {
    my $self = shift;
    my $args  = shift;

    my $text = $self->text_with_one_nl;
    unless ( defined $text and $text ne '' ) {
        return [];
    }

	# Do we really need an update?
	require Digest::MD5;
	my $md5 = Digest::MD5::md5_hex( Encode::encode_utf8($text) );
	unless ( $args->{force} ) {
		if ( defined( $self->{last_syncheck_md5} )
			and $self->{last_syncheck_md5} eq $md5 )
		{
			return;
		}
	}
	$self->{last_syncheck_md5} = $md5;

    require Padre::Task::SyntaxChecker::Perl6;
    my $task = Padre::Task::SyntaxChecker::Perl6->new(
        notebook_page => $self->editor,
        text => $text,
        issues => $self->{issues},
        ( exists $args->{on_finish} ? (on_finish => $args->{on_finish}) : () ),
    );
    if ($args->{background}) {
        # asynchroneous execution (see on_finish hook)
        $task->schedule();
        return();
    }
    else {
        # serial execution, returning the result
        return() if $task->prepare() =~ /^break$/;
        $task->run();
        return $task->{syntax_check};
    }
    return;
}

sub keywords {
    my $self = shift;
    if (! defined $self->{keywords}) {
        #Get keywords from Plugin object
        my $manager = Padre->ide->plugin_manager;
        if($manager) {
            my $plugin = $manager->plugins->{'Perl6'};
            if($plugin) {
                my %perl6_functions = %{$plugin->object->{perl6_functions}};
                foreach my $function (keys %perl6_functions) {
                    my $docs = $perl6_functions{$function};
                    # limit calltip size to n-lines
                    my @lines = split /\n/, $docs;
                    if(scalar @lines > $CALLTIP_DISPLAY_COUNT) {
                        $docs = (join "\n", @lines[0..$CALLTIP_DISPLAY_COUNT-1]) .
                            "\n...";
                    }
                    $self->{keywords}->{$function} = {
                        'cmd' => $docs,
                        'exp' => '',
                    };
                }
             }
        }
    }
    return $self->{keywords};
}

sub comment_lines_str { return '#' }

sub event_on_right_down {
	my ($self, $editor, $menu, $event ) = @_;
	#print "event_on_right_down @_\n";
	my $pos = $editor->GetCurrentPos;
	
	return if not $self->{_parse_tree};

	my @things;
	foreach my $e (@{ $self->{_parse_tree} }) {
		last if $e->{start} > $pos;
		next if $e->{start} + $e->{length} < $pos;
		push @things, {type => $e->{type}, str => $e->{str}};
	}
	return if not @things;
	
	my $main = $editor->main;
	$menu->AppendSeparator;
	
#	my $perl6 = $menu->Append( -1, Wx::gettext("Perl 6 $pos") );
#	Wx::Event::EVT_MENU(
#			$main, $perl6,
#				sub {
#					print "$_[0]\n";
#				},
#			);
	foreach my $thing (@things) {
		$menu->Append( -1, Wx::gettext("$thing->{str} is Perl 6 $thing->{type} ") );
	}
	return;
}

sub get_outline {
	my $self = shift;
	my %args = @_;

	my $tokens = $self->{tokens};
	
	if(not defined $tokens) {
		return;
	}
	
	my $text = $self->text_get;
	unless ( defined $text and $text ne '' ) {
		return [];
	}

	# Do we really need an update?
	require Digest::MD5;
	my $md5 = Digest::MD5::md5_hex( Encode::encode_utf8($text) );
	unless ( $args{force} ) {
		if ( defined( $self->{last_outline_md5} )
			and $self->{last_outline_md5} eq $md5 )
		{
			return;
		}
	}
	$self->{last_outline_md5} = $md5;

	require Padre::Task::Outline::Perl6;
	my $task = Padre::Task::Outline::Perl6->new(
		editor => $self->editor,
		text   => $text,
		tokens => $tokens,
	);

	# asynchronous execution (see on_finish hook)
	$task->schedule;
	return;
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
