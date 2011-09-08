package Padre::Plugin::PerlCritic;

# ABSTRACT: Analyze perl files with Perl::Critic

use 5.008;
use strict;
use warnings;
use Padre::Wx     ();
use Padre::Plugin ();

our $VERSION = '0.13';

our @ISA = 'Padre::Plugin';
#######
# Method Padre_Interfaces required
#######
sub padre_interfaces {
	return (
		'Padre::Plugin'   => '0.91',
		'Padre::Wx'       => '0.91',
		'Padre::Wx::Main' => '0.91',
		'Padre::Logger'   => '0.91',
	);
}

sub plugin_name {
	return Wx::gettext('Perl-Critic');
}

sub menu_plugins {
	my $self = shift;
	my $main = shift;

	# Create a manual menu item
	my $item = Wx::MenuItem->new( undef, -1, $self->plugin_name, );
	Wx::Event::EVT_MENU(
		$main, $item,
		sub {
			local $@;
			eval { $self->critic($main); };
		},
	);

	return $item;
}

sub critic {
	my $self    = shift;
	my $current = $self->current;
	$DB::single = 1;

	# Get the document to critique
	my $document = $current->document or return;
	unless ( $document->isa('Padre::Document::Perl') ) {
		return Wx::MessageBox(
			Wx::gettext('Document is not a Perl document'),
			Wx::gettext('Error'), Wx::wxOK | Wx::wxCENTRE, $self,
		);
	}
	my $text = $document->text_get;
	return unless defined $text;

	# Do we have a project-specific configuration
	my $project           = $document->project;
	my $config            = $project->config;
	my $config_perlcritic = $config->config_perlcritic;
	my @params =
		$config_perlcritic
		? ( -profile => $config_perlcritic )
		: ();

	# Open and start output from the critic run
	my $main   = $current->main;
	my $output = $main->output;
	$output->clear;
	$main->show_output(1);
	if (@params) {
		$output->AppendText(
			sprintf(
				Wx::gettext('Perl::Critic running with project-specific configuration %s'),
				$config_perlcritic
				)
				. "\n"
		);
	} else {
		$output->AppendText( Wx::gettext('Perl::Critic running with default or user configuration') . "\n" );
	}

	# Hand off to Perl::Critic
	require Perl::Critic;
	my $critic     = Perl::Critic->new(@params);
	my @violations = $critic->critique( \$text );

	# Write the results to the Output window
	if (@violations) {
		$output->AppendText( join '', @violations );
	} else {
		$output->AppendText( Wx::gettext('Perl::Critic found nothing to say about this code') . "\n" );
	}

	return;
}

#######
# Method plugin_disable required
#######
sub plugin_disable {
	my $self = shift;

	# Unload other cpan modules
	$self->unload(
		qw{
			Perl::Critic
			}
	);

	$self->SUPER::plugin_disable(@_);

	return 1;
}

1;

__END__

=head1 SYNOPSIS

This is a simple plugin to run Perl::Critic on your source code.

Currently there is no configuration for this plugin, so you have to rely
on the default .perlcriticrc configuration. See Perl::Critic for details.
