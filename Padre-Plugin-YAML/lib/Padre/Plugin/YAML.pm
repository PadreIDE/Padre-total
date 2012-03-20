package Padre::Plugin::YAML;

use v5.10;
use strict;
use warnings;

use Padre::Plugin ();
use Padre::Wx     ();
use Try::Tiny;

our $VERSION = '0.04';
use parent qw(Padre::Plugin);

# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::YAML
	Padre::Plugin::YAML::Document
	Padre::Plugin::YAML::Syntax
};

#######
# Called by padre to know the plugin name
#######
sub plugin_name {
	return Wx::gettext('YAML');
}

#######
# Called by padre to check the required interface
#######
sub padre_interfaces {
	return (
		'Padre::Plugin'       => '0.94',
		'Padre::Document'     => '0.94',
		'Padre::Wx'           => '0.94',
		'Padre::Task::Syntax' => '0.94',
		'Padre::Logger'       => '0.94',
	);
}

#######
# Called by padre to know which document to register for this plugin
#######
sub registered_documents {
	return (
		'text/x-yaml' => 'Padre::Plugin::YAML::Document',
	);
}

#######
# Called by padre to build the menu in a simple way
#######
sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext('About') => sub { $self->show_about },
	];
}

#######
# Shows the about dialog for this plugin
#######
sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName( Wx::gettext('YAML Plug-in') );
	my $authors     = 'Zeno Gantner';
	my $description = Wx::gettext( <<'END' );
YAML support for Padre

Copyright 2011-2012 %s
This plug-in is free software; you can redistribute it and/or modify it under the same terms as Padre.
END
	$about->SetDescription( sprintf( $description, $authors ) );

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}

#######
# Called by Padre when this plugin is disabled
#######
sub plugin_disable {
	my $self = shift;

	# Unload all our child classes
	# TODO: Switch to Padre::Unload once Padre 0.96 is released
	for my $package (CHILDREN) {
		require Padre::Unload;
		Padre::Unload->unload($package);
	}

	$self->SUPER::plugin_disable(@_);

	return 1;
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::YAML - YAML support for Padre The Perl IDE


=head1 VERSION

This document describes Padre::Plugin::YAML version 0.04


=head1 DESCRIPTION

YAML support for Padre, the Perl Application Development and Refactoring
Environment.

Syntax highlighting for YAML is supported by Padre out of the box.
This plug-in adds some more features to deal with YAML files.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.


=head1 METHODS

=over 6

=item * menu_plugins_simple

=item * padre_interfaces

=item * plugin_disable

=item * plugin_name

=item * registered_documents

=item * show_about

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Padre::Plugin::YAML

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-YAML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-YAML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-YAML>

=item * Search CPAN

L<http://search.cpan.org/dist/Padre-Plugin-YAML/>

=back


=head1 AUTHOR

Zeno Gantner E<lt>zenog@cpan.orgE<gt>

=head1 CONTRIBUTORS

Kevin Dawson  E<lt>bowtie@cpan.orgE<gt>

Ahmad M. Zawawi E<lt>ahmad.zawawi@gmail.comE<gt>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011-2012, Zeno Gantner E<lt>zenog@cpan.orgE<gt>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
