package Padre::Wx::App;

=pod

=head1 NAME

Padre::Wx::App - Padre main Wx application abstraction

=head1 DESCRIPTION

For architectural clarity, L<Padre> maintains two separate collections
of resources, a Wx object tree representing the literal GUI elements,
and a second tree of objects representing the abstract concepts, such
as configuration, projects, and so on.

B<Padre::Wx::App> is a L<Wx::App> subclass that represents the Wx
application as a whole, and acts as the root of the object tree for
the GUI elements.

From the main L<Padre> object, it can be accessed via the C<wx> method.

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use Padre::Wx ();

our $VERSION = '0.23';
our @ISA     = 'Wx::App';

use Class::XSAccessor
	getters => {
		main_window => 'main_window',
	};





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Immediately populate the main window
	$self->{main_window} = Padre::Wx::MainWindow->new;

	return $self;
}

sub OnInit { 1 }





#####################################################################
# Padre Methods

=pod

=head2 main_window

The C<main_window> method creates or returns the existing
L<Padre::Wx::MainWindow> object, representing the main editor window
of the application.

=cut

1;

=pod

=head1 COPYRIGHT

Copyright 2008 Gabor Szabo.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut
