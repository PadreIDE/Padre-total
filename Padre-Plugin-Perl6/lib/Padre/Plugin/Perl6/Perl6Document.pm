package Padre::Plugin::Perl6::Perl6Document;

use 5.010;
use strict;
use warnings;

use Padre::Wx ();

our $VERSION = '0.57';
our @ISA     = 'Padre::Document';

# get Perl6 (rakudo) command line for "Run script" F5 Padre menu item
sub get_command {
	my $self = shift;

	my $filename = $self->filename;
	require Padre::Plugin::Perl6::Util;
	my $perl6 = Padre::Plugin::Perl6::Util::perl6_exe();

	if ( not $perl6 ) {
		my $main = Padre->ide->wx->main;
		$main->error(
			"Either perl6 needs to be in the PATH or RAKUDO_DIR must point to the directory of the Rakudo checkout.");
		return;
	}

	return qq{"$perl6" "$filename"};
}

# Checks the syntax of a Perl document.
# Documented in Padre::Document!
# Implemented as a task. See Padre::Plugin::Perl6::Perl6SyntaxChecker
sub check_syntax {
	my $self = shift;
	my %args = @_;
	$args{background} = 0;
	return $self->_check_syntax_internals( \%args );
}

sub check_syntax_in_background {
	my $self = shift;
	my %args = @_;
	$args{background} = 1;
	return $self->_check_syntax_internals( \%args );
}

sub _check_syntax_internals {
	my $self = shift;
	my $args = shift;

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

	require Padre::Plugin::Perl6::Perl6SyntaxCheckerTask;
	my $task = Padre::Plugin::Perl6::Perl6SyntaxCheckerTask->new(
		notebook_page => $self->editor,
		text          => $text,
		issues        => $self->{issues},
		( exists $args->{on_finish} ? ( on_finish => $args->{on_finish} ) : () ),
	);
	if ( $args->{background} ) {

		# asynchroneous execution (see on_finish hook)
		$task->schedule();
		return ();
	} else {

		# serial execution, returning the result
		return () if $task->prepare() =~ /^break$/;
		$task->run();
		return $task->{syntax_check};
	}
	return;
}

# In Perl 6 the best way to comment the current error reliably is
# by putting a hash and a space since #( is an embedded comment in Perl 6!
# see S02:166
sub comment_lines_str {
	return '# ';
}

#
# Guess the new line for the current document
# can return \r, \r\n, or \n
#
sub guess_newline {
	my $self = shift;

	require Padre::Util;
	my $doc_new_line_type = Padre::Util::newline_type( $self->text_get );
	my $new_line;
	if ( $doc_new_line_type eq "WIN" ) {
		$new_line = "\r\n";
	} elsif ( $doc_new_line_type eq "MAC" ) {
		$new_line = "\r";
	} else {

		#NONE, UNIX or MIXED
		$new_line = "\n";
	}

	return $new_line;
}

#
# Returns the Outline tree
#
sub get_outline {
	my $self = shift;
	my %args = @_;

	my $tokens = $self->{tokens};

	if ( not defined $tokens ) {
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

	require Padre::Plugin::Perl6::Perl6OutlineTask;
	my $task = Padre::Plugin::Perl6::Perl6OutlineTask->new(
		editor => $self->editor,
		text   => $text,
		tokens => $tokens,
	);

	# asynchronous execution (see on_finish hook)
	$task->schedule;
	return;
}

#
# Returns the help provider
#
sub get_help_provider {
	require Padre::Plugin::Perl6::Perl6HelpProvider;
	return Padre::Plugin::Perl6::Perl6HelpProvider->new;
}

#
# Returns the quick fix provider
#
sub get_quick_fix_provider {
	require Padre::Plugin::Perl6::Perl6QuickFixProvider;
	return Padre::Plugin::Perl6::Perl6QuickFixProvider->new;
}

1;

__END__

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

Gabor Szabo L<http://szabgab.com/>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Padre Developers as in Perl6.pm

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.
