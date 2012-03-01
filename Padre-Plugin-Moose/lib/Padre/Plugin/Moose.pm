package Padre::Plugin::Moose;

use 5.008;
use strict;
use warnings;
use Padre::Plugin ();

our $VERSION = '0.16';
our @ISA     = 'Padre::Plugin';

# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::Moose::Role::CanGenerateCode
	Padre::Plugin::Moose::Role::CanHandleInspector
	Padre::Plugin::Moose::Role::CanProvideHelp
	Padre::Plugin::Moose::Role::HasClassMembers
	Padre::Plugin::Moose::Attribute
	Padre::Plugin::Moose::Class
	Padre::Plugin::Moose::ClassMember
	Padre::Plugin::Moose::Constructor
	Padre::Plugin::Moose::Destructor
	Padre::Plugin::Moose::Document
	Padre::Plugin::Moose::Method
	Padre::Plugin::Moose::Program
	Padre::Plugin::Moose::Role
	Padre::Plugin::Moose::Subtype
	Padre::Plugin::Moose::Util
	Padre::Plugin::Moose::Main
	Padre::Plugin::Moose::FBP::Main
};





######################################################################
# Padre Integration

sub padre_interfaces {
	'Padre::Plugin'           => 0.94,
	'Padre::Document'         => 0.94,
	'Padre::Wx::Main'         => 0.94,
	'Padre::Wx::Theme'        => 0.94,
	'Padre::Wx::Editor'       => 0.94,
	'Padre::Wx::Role::Main'   => 0.94,
	'Padre::Wx::Role::Dialog' => 0.94,
}

sub registered_documents {
	'application/x-perl' => 'Padre::Plugin::Moose::Document',;
}





######################################################################
# Padre::Plugin Methods

sub plugin_name {
	Wx::gettext('Moose');
}

sub plugin_disable {
	my $self = shift;

	# Destroy resident dialog
	if ( defined $self->{dialog} ) {
		$self->{dialog}->Destroy;
		$self->{dialog} = undef;
	}

	# TODO: Switch to Padre::Unload once Padre 0.96 is released
	require Padre::Unload;
	for my $package ( CHILDREN ) {
		Padre::Unload->unload($package);
	}
}

# The command structure to show in the Plugins menu
sub menu_plugins {
	my $self      = shift;
	my $main      = $self->main;
	my $menu_item = Wx::MenuItem->new( undef, -1, $self->plugin_name . "...\tF8", );
	Wx::Event::EVT_MENU(
		$main,
		$menu_item,
		sub {
			eval {
				$self->dialog->run;
			};
			return unless $@;
			$main->error(
				sprintf( Wx::gettext('Error: %s'), $@ )
			);
		},
	);

	return $menu_item;
}





######################################################################
# Support Methods

sub dialog {
	my $self = shift;
	unless ( defined $self->{dialog} ) {
		require Padre::Plugin::Moose::Main;
		$self->{dialog} = Padre::Plugin::Moose::Main->new($self->main);
	}
	return $self->{dialog};
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Moose - Moose support for Padre

=head1 SYNOPSIS

    cpan Padre::Plugin::Moose;

Then use it via L<Padre>, The Perl IDE.

=head1 DESCRIPTION

Once you enable this Plugin under Padre, you'll get a brand new menu with the following options:

=head2 Moose...

Opens up a user-friendly dialog where you can add classes, roles, attributes, subtypes and methods.
The dialog contains a tree of class/role elements that are created while it is open and a preview of
generated Perl code. It also contains links to Moose manual, cookbook and website.

=head1 BUGS

Please report any bugs or feature requests to C<bug-padre-plugin-Moose at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-Moose>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Padre::Plugin::Moose

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-Moose>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-Moose>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-Moose>

=item * Search CPAN

L<http://search.cpan.org/dist/Padre-Plugin-Moose/>

=back

=head1 SEE ALSO

L<Moose>, L<Padre>

=head1 AUTHORS

=over 4

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ahmad M. Zawawi

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
