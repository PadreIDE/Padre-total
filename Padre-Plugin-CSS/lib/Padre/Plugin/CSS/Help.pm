package Padre::Plugin::CSS::Help;

# ABSTRACT: CSS Help provider

use 5.008;
use strict;
use warnings;
use Carp       ();
use File::Spec ();
use YAML::Tiny qw(LoadFile);

use Padre::Help ();
use Padre::Util ();

our @ISA = 'Padre::Help';

our $VERSION = '0.15';

my $data;

sub help_init {
	my ($self) = @_;

	my $help_file = File::Spec->catfile( Padre::Util::share('CSS'), 'css.yml' );
	$data = LoadFile($help_file);

	return;
}

sub help_list {
	my ($self) = @_;

	$self->help_init unless $data;
	return [ keys %{ $data->{topics} } ];
}

sub help_render {
	my ( $self, $topic ) = @_;

	#warn "'$topic'";
	$topic =~ s/://;
	my $html = "No help found for '$topic'";
	if ( $data->{topics}{$topic} ) {
		$html = "$topic $data->{topics}{$topic}";
		$html =~ s/REPLACE_(\w+)/$data->{replace}{$1}/g;
	}
	my $location = $topic;
	return ( $html, $location );
}

1;

