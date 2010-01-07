package Padre::Plugin::PerlCritic;

use strict;
use warnings;
use Padre::Wx     ();
use Padre::Util   ('_T');
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
	return 'Padre::Plugin' => '0.26';
}

sub menu_plugins_simple {
	return PerlCritic => [
		_T('Run PerlCritic') => \&critic,
	];
}

sub critic {
	my ($self) = @_;

	my $doc = $self->current->document;
	my $src = $doc->text_get;
	return unless defined $src;

	if ( !$doc->isa('Padre::Document::Perl') ) {
		return Wx::MessageBox( _T('Document is not a Perl document'), _T('Error'), Wx::wxOK | Wx::wxCENTRE, $self );
	}

	require Perl::Critic;

	my $critic     = Perl::Critic->new();
	my @violations = $critic->critique( \$src );

#    my $main      = Padre->ide->wx->main_window;
#    my $errorlist = $main->errorlist;
#    $errorlist->enable;
#    $errorlist->clear;
#    my @out = map { [ $_->location, $doc->filename, $_->explanation ] } @violations;

	my $output = @violations ? join '', @violations : 'Perl::Critic found nothing to say about this code';
	Padre::Current->main->output->clear;

	Padre::Current->main->output->AppendText( "$output\n" );
	Padre::Current->main->show_output(1);

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
