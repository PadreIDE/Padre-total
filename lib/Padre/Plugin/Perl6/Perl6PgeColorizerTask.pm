package Padre::Plugin::Perl6::Perl6PgeColorizerTask;

use strict;
use warnings;
use base 'Padre::Task';

our $VERSION = '0.45';
our $thread_running = 0;

# This is run in the main thread before being handed
# off to a worker (background) thread. The Wx GUI can be
# polled for information here.
# If you don't need it, just inherit this default no-op.
sub prepare {
	my $self = shift;

	# it is not running yet.
	$self->{broken} = 0;
	
	# put editor into main-thread-only storage
	$self->{main_thread_only} ||= {};
	my $document = $self->{document} || $self->{main_thread_only}{document};
	my $editor = $self->{editor} || $self->{main_thread_only}{editor};
	delete $self->{document};
	delete $self->{editor};
	$self->{main_thread_only}{document} = $document;
	$self->{main_thread_only}{editor} = $editor;

	# assign a place in the work queue
	if($thread_running) {
		# single thread instance at a time please. aborting...
		$self->{broken} = 1;
		return "break";
	}
	$thread_running = 1;
	return 1;
}

sub is_broken {
	my $self = shift;
	return $self->{broken};
}

# used for coloring by parrot
my %colors = (
	quote_expression => Padre::Constant::PADRE_BLUE,
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
	post => Padre::Constant::PADRE_MAGENTA,
	dotty => undef,
	dottyop => undef,
	methodop => Padre::Constant::PADRE_GREEN,
	name => Padre::Constant::PADRE_GREEN,
	identifier => undef,
	term => undef,
	args => undef,
	arglist => undef,
	EXPR => undef,
	statement_control => undef,
	use_statement => undef,
	sym => Padre::Constant::PADRE_RED,
	'infix:='  => Padre::Constant::PADRE_GREEN,
	'infix:+'  => Padre::Constant::PADRE_GREEN,
	'infix:,'  => Padre::Constant::PADRE_GREEN,
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
	variable => Padre::Constant::PADRE_RED,
	integer => undef,
	number => Padre::Constant::PADRE_BROWN,
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
	lambda => Padre::Constant::PADRE_GREEN,
);

# This is run in the main thread after the task is done.
# It can update the GUI and do cleanup.
# You don't have to implement this if you don't need it.
sub finish {
	my $self = shift;
	my $mainwindow = shift;

	my $doc = $self->{main_thread_only}{document};
	my $editor = $self->{main_thread_only}{editor};
	if($self->{_parse_tree}) {
		$doc->remove_color;
		foreach my $pd (@{$self->{_parse_tree}}) {
			my $type = $pd->{type};
			if (not exists ($colors{$type})) {
				warn "No Perl6 color definiton for '$type':  " . 
					$pd->{str} . "\n";
				next;
			}
			if(not defined $colors{$type}) {
				# no need to color
				next;
			}
			my $color = $colors{$type};
			$editor->StartStyling($pd->{start}, $color);
			$editor->SetStyling($pd->{length}, $color);
		}
	}
	$doc->{tokens} = [];
	$doc->{issues} = [];
	
	$doc->check_syntax_in_background(force => 1);
	$doc->get_outline(force => 1);

	# finished here
	$thread_running = 0;

	return 1;
}

# Task thread subroutine
sub run {
	my $self = shift;

	require Padre::Plugin::Perl6::Util;
	my $perl6 = Padre::Plugin::Perl6::Util::get_perl6();
	if ($perl6) {
		use File::Temp qw(tempdir);
		my $dir = tempdir(CLEANUP => 1);
		my $file = "$dir/file";

		open my $fh, '>', $file or warn "Could not open $file for writing\n";
		print $fh $self->{text};
		delete $self->{text};

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
		}
		$self->{_parse_tree} = \@pd;
		return;
	}
	
	return 1;
};

1;
