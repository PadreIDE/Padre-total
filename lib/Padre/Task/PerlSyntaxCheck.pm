
package Padre::Task::PerlSyntaxCheck;
use strict;
use warnings;

require Padre;
use base qw{Padre::Task};


sub run {
	my $self = shift;
	my $filename = $self->{filename};
	my @inc = map { " -I" . $_ } @INC; # TODO hack! Replace with project support
	require Time::HiRes;
	warn Time::HiRes::time() . " - Starting check." ;
	$self->{result} = `$^X -I. -Ilib@inc -Mdiagnostics -c $filename 2>&1 1>/dev/null`;
	warn Time::HiRes::time() . " - Finished check." ;
	return 1;
}

sub finish {
	my $self = shift;
	my $issues = $self->_process_syntax_check_results();
	Padre->ide->wx->main_window->syntax_checker->update_gui_with_syntax_check_results(
		$issues, $self->{notebook_page_id}
	);
	return 1;
}

sub _process_syntax_check_results {
	my $self = shift;
	my $result = $self->{result};
	my $page_id = $self->{notebook_page_id};
	my $document = Padre->ide->wx->main_window->{notebook}->GetPage($page_id)->{Document};

	# Don't really know where that comes from...
	my $i = index( $result, 'Uncaught exception from user code' );
	if ( $i > 0 ) {
		$result = substr( $result, 0, $i );
	}

	my $nlchar = "\n";
	if ( $document->get_newline_type eq 'WIN' ) {
		$nlchar = "\r\n";
	}
	elsif ( $document->get_newline_type eq 'MAC' ) {
		$nlchar = "\r";
	}

	return [] if $result =~ /\A[^\n]+syntax OK$nlchar\z/o;

	$result =~ s/$nlchar$nlchar/$nlchar/go;
	$result =~ s/$nlchar\s/\x1F /go;
	my @msgs = split(/$nlchar/, $result);

	my $issues = [];
	my @diag = ();
	foreach my $msg ( @msgs ) {
		if (   index( $msg, 'has too many errors' )    > 0
			or index( $msg, 'had compilation errors' ) > 0
			or index( $msg, 'syntax OK' ) > 0
		) {
			last;
		}

		my $cur = {};
		my $tmp = '';

		if ( $msg =~ s/\s\(\#(\d+)\)\s*\Z//o ) {
			$cur->{diag} = $1 - 1;
		}

		if ( $msg =~ m/\)\s*\Z/o ) {
			my $pos = rindex( $msg, '(' );
			$tmp = substr( $msg, $pos, length($msg) - $pos, '' );
		}

		if ( $msg =~ s/\s\(\#(\d+)\)(.+)//o ) {
			$cur->{diag} = $1 - 1;
			my $diagtext = $2;
			$diagtext =~ s/\x1F//go;
			push @diag, join( ' ', split( ' ', $diagtext ) );
		}

		if ( $msg =~ s/\sat(?:\s|\x1F)+.+?(?:\s|\x1F)line(?:\s|\x1F)(\d+)//o ) {
			$cur->{line} = $1;
			$cur->{msg}  = $msg;
		}

		if ($tmp) {
			$cur->{msg} .= "\n" . $tmp;
		}

		$cur->{msg} =~ s/\x1F/$nlchar/go;

		if ( defined $cur->{diag} ) {
			$cur->{desc} = $diag[ $cur->{diag} ];
			delete $cur->{diag};
		}
		if (   defined( $cur->{desc} )
			&& $cur->{desc} =~ /^\s*\([WD]/o
		) {
			$cur->{severity} = 'W';
		}
		else {
			$cur->{severity} = 'E';
		}

		push @{$issues}, $cur;
	}

	return $issues;

}
1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
