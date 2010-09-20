package Padre::HelpProvider::PIR;

use 5.008;
use strict;
use warnings;

use Cwd ();
use Padre::Logger;
use Padre::Help            ();
use Padre::DocBrowser::POD ();
use Padre::Pod2HTML        ();
use Padre::Util            ();

our $VERSION = '0.27';
our @ISA     = 'Padre::Help';

#
# Initialize help
#
sub help_init {
	my $self = shift;

	# TODO factor out and stop requireing PARROT_DIR
	return if not $ENV{PARROT_DIR};

	# TODO what is the difference between docs/book/pir and docs/ops ?
	my $dir = "$ENV{PARROT_DIR}/docs/ops";

	my %index;

	#foreach my $file ('io.pod') {
	#my $path = "$dir/$file";
	foreach my $path ("$ENV{PARROT_DIR}/docs/pdds/pdd19_pir.pod") {
		open my $fh, '<', $path;
		if ( !$fh ) {
			warn "Could not open $path $!";
			next;
		}
		my %item;
		my $cnt = 0;
		my $topic;
		while ( my $line = <$fh> ) {
			$cnt++;
			if ( $line =~ /=item\s+(\.\w+)/ ) {
				if ($topic) {
					TRACE($topic) if DEBUG;
					$item{end} = $cnt - 1;
					push @{ $index{$topic} }, {%item};
				}
				$topic = $1;
				%item = ( start => $cnt, file => $path );
				next;
			}
			if ( $line =~ /^=/ and $topic ) {
				$item{end} = $cnt - 1;
				push @{ $index{$topic} }, {%item};
				$topic = undef;
				%item  = ();
				next;
			}
		}
	}
	foreach my $path ( glob "$dir/*.pod" ) {
		if ( open my $fh, '<', $path ) {
			my %item;
			my $cnt = 0;
			my $topic;
			while ( my $line = <$fh> ) {
				$cnt++;
				if ( $line =~ /=item\s+B<(\w+)>/ ) {
					if ($topic) {
						TRACE($topic) if DEBUG;
						$item{end} = $cnt - 1;
						push @{ $index{$topic} }, {%item};
					}
					$topic = $1;
					%item = ( start => $cnt, file => $path );
					next;
				}
				if ( $line =~ /^=/ and $topic ) {
					$item{end} = $cnt - 1;
					push @{ $index{$topic} }, {%item};
					$topic = undef;
					%item  = ();
					next;
				}
			}
		} else {
			warn "Could not open '$path': $!";
		}
	}

	$self->{pir} = \%index;
}


#
# Renders the help topic content into XHTML
#
sub help_render {
	my ( $self, $topic ) = @_;
	my ( $html, $location );

	TRACE("render '$topic'") if DEBUG;

	#use Data::Dumper;
	#TRACE(Dumper $self->{pir}) if DEBUG;
	return if not $self->{pir}->{$topic};
	my $pod;

	# TODO read the files only once!?
	foreach my $x ( @{ $self->{pir}->{$topic} } ) {
		if ( open my $fh, '<', $x->{file} ) {
			my @lines = <$fh>;
			$pod .= join '', @lines[ $x->{start} .. $x->{end} ];
		}
	}
	TRACE($pod) if DEBUG;
	$html = Padre::Pod2HTML->pod2html($pod);
	TRACE($html) if DEBUG;

	# Render using perldoc pseudo code package
	#my $pod      = Padre::DocBrowser::POD->new;
	#my $doc      = $pod->resolve( $topic, $hints );
	#my $pod_html = $pod->render($doc);
	#$html = $pod_html->body if $pod_html;
	return ( $html, $location || $topic );
}

#
# Returns the help topic list
#
sub help_list {
	my $self = shift;
	return [ sort keys %{ $self->{pir} } ];
}

1;

__END__

=head1 NAME

Padre::HelpProvider::Perl - Perl 5 Help Provider

=head1 DESCRIPTION

Perl 5 Help index is built here and rendered.

=head1 AUTHOR

Gabor Szabo L<http://szabgab.com/>

Ahmad M. Zawawi C<ahmad.zawawi@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Padre Developers as in Parrot.pm

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.
