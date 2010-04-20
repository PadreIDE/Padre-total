package Padre::Task::SyntaxChecker::Perl;

use 5.008;
use strict;
use warnings;
use Padre::Perl                ();
use Padre::Constant            ();
use Padre::Task::SyntaxChecker ();

our $VERSION = '0.60';
our @ISA     = 'Padre::Task::SyntaxChecker';

use version;

=pod

=head1 NAME

Padre::Task::SyntaxChecker::Perl - Perl document syntax-checking in the background

=head1 SYNOPSIS

  # by default, the text of the current document
  # will be fetched as will the document's notebook page.
  my $task = Padre::Task::SyntaxChecker::Perl->new(
    newlines => "\r\n", # specify the newline type!
  );
  $task->schedule;
  
  my $task2 = Padre::Task::SyntaxChecker::Perl->new(
    text          => Padre::Current->document->text_get,
    editor => Padre::Current->editor,
    on_finish     => sub { my $task = shift; ... },
    newlines      => "\r\n", # specify the newline type!
  );
  $task2->schedule;

=head1 DESCRIPTION

This class implements syntax checking of Perl documents in
the background. It inherits from L<Padre::Task::SyntaxChecker>.
Please read its documentation!

=cut

sub run {
	my $self = shift;
	$self->_check_syntax;
	return 1;
}

sub _check_syntax {
	my $self = shift;

	my $nlchar = $self->{newlines};
	$self->{text} =~ s/$nlchar/\n/g if defined $nlchar;

	# Execute the syntax check
	my $stderr = '';
	my $testfilename;
	SCOPE: {

		# Create a temporary file with the Perl text
		require File::Temp;
		my $file = File::Temp->new( UNLINK => 1 );
		binmode( $file, ":utf8" );
		$file->print( $self->{text} );
		$file->close;
		$testfilename = $file->filename;

		# Run with console Perl to prevent unexpected results under wperl
		my @cmd = (
			Padre::Perl::cperl(),
		);

		# Append Perl command line options
		if ( $self->{perl_cmd} ) {
			push @cmd, @{ $self->{perl_cmd} };
		}

		# Open a temporary file for standard error redirection
		my $err = File::Temp->new( UNLINK => 1 );
		$err->close;

		# Redirect perl's output to temporary file
		push @cmd,
			(
			'-Mdiagnostics',
			'-c',
			$file->filename,
			'2>' . $err->filename,
			);

		# We need shell redirection (list context does not give that)
		my $cmd = join ' ', @cmd;

		# Make sure we execute from the correct directory
		if (Padre::Constant::WIN32) {
			require Padre::Util::Win32;
			Padre::Util::Win32::ExecuteProcessAndWait(
				directory  => $self->{cwd},
				file       => 'cmd.exe',
				parameters => "/C $cmd",
			);
		} else {
			if ( $self->{cwd} ) {
				require File::pushd;
				my $pushd = File::pushd::pushd( $self->{cwd} );
				system $cmd;
			} else {
				system $cmd;
			}
		}

		# Slurp Perl's stderr
		open my $fh, '<', $err->filename or die $!;
		local $/ = undef;
		$stderr = <$fh>;
		close $fh;

		# and delete it
		unlink $err->filename;
	}

	# Don't really know where that comes from...
	my $i = index( $stderr, 'Uncaught exception from user code' );
	if ( $i > 0 ) {
		$stderr = substr( $stderr, 0, $i );
	}

	# Handle the "no errors or warnings" case
	if ( $stderr =~ /^\s+syntax OK\s+$/s ) {
		return [];
	}

	# Split into message paragraphs
	$stderr =~ s/\n\n/\n/go;
	$stderr =~ s/\n\s/\x1F /go;
	my @messages = split( /\n/, $stderr );

	my $issues = [];
	my @diag   = ();
	foreach my $message (@messages) {
		if (   index( $message, 'has too many errors' ) > 0
			or index( $message, 'had compilation errors' ) > 0
			or index( $message, 'syntax OK' ) > 0 )
		{
			last;
		}

		my $cur = {};
		my $tmp = '';

		if ( $message =~ s/\s\(\#(\d+)\)\s*\Z//o ) {
			$cur->{diag} = $1 - 1;
		}

		if ( $message =~ m/\)\s*\Z/o ) {
			my $pos = rindex( $message, '(' );
			$tmp = substr( $message, $pos, length($message) - $pos, '' );
		}

		if ( $message =~ s/\s\(\#(\d+)\)(.+)//o ) {
			$cur->{diag} = $1 - 1;
			my $diagtext = $2;
			$diagtext =~ s/\x1F//go;
			push @diag, join( ' ', split( ' ', $diagtext ) );
		}

		if ( $message =~ s/\sat(?:\s|\x1F)+(.+?)(?:\s|\x1F)line(?:\s|\x1F)(\d+)//o ) {
			next if $1 ne $testfilename;
			$cur->{line} = $2;
			$cur->{msg}  = $message;
		}

		if ($tmp) {
			$cur->{msg} .= "\n" . $tmp;
		}

		if ( defined $cur->{msg} ) {
			$cur->{msg} =~ s/\x1F/\n/go;
		}

		if ( defined $cur->{diag} ) {
			$cur->{desc} = $diag[ $cur->{diag} ];
			delete $cur->{diag};
		}
		if ( defined( $cur->{desc} )
			&& $cur->{desc} =~ /^\s*\([WD]/o )
		{
			$cur->{severity} = 'W';
		} else {
			$cur->{severity} = 'E';
		}
		delete $cur->{desc};

		push @{$issues}, $cur;
	}

	$self->{syntax_check} = $issues;
}

1;

__END__

=head1 SEE ALSO

This class inherits from L<Padre::Task::SyntaxChecker> which
in turn is a L<Padre::Task> and its instances can be scheduled
using L<Padre::TaskManager>.

The transfer of the objects to and from the worker threads is implemented
with L<Storable>.

=head1 AUTHOR

Steffen Mueller C<smueller@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
