package Padre::Plugin::PerlCritic;

use 5.008;
use strict;
use warnings;
use Padre::Wx     ();
use Padre::Plugin ();

our $VERSION = '0.07';

=pod

=head1 NAME

Padre::Plugin::PerlCritic - Analyze perl files with Perl::Critic

=head1 SYNOPIS

This is a simple plugin to run Perl::Critic on your source code.

Currently there is no configuration for this plugin, so you have to rely
on the default .perlcriticrc configuration. See Perl::Critic for details.

=cut

sub padre_interfaces {
	'Padre::Plugin' => '0.26',
	'Padre::Config' => '0.54',
}

sub menu_plugins_simple {
	my $self = shift;
	return PerlCritic => [
		Wx::gettext('Run PerlCritic') => sub {
			$self->critic(@_);
		}
	];
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
			Wx::gettext('Error'),
			Wx::wxOK | Wx::wxCENTRE,
			$self,
		);
	}
	my $text = $document->text_get;
	return unless defined $text;

	# Do we have a project-specific configuration
	my $project = $document->project;
	my $config  = $project->config;
	my @params  = $config->config_perlcritic
		? ( -profile => $config->config_perlcritic )
		: ();

	# Hand off to Perl::Critic
	require Perl::Critic;
	my $critic     = Perl::Critic->new( @params );
	my @violations = $critic->critique( \$text );

	# Write the results to the Output window
	my $main   = $current->main;
	my $output = $main->output;
	$output->clear;
	if ( @violations ) {
		$output->AppendText(join '', @violations);
	} else {
		$output->AppendText(
			Wx::gettext('Perl::Critic found nothing to say about this code')
		);
	}
	$main->show_output(1);

	return;
}

1;

__END__

=pod

=head1 AUTHOR

Kaare Rasmussen E<lt>kaare@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Kaare Rasmussen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
