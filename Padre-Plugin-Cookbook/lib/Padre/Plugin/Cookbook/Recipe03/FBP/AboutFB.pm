package Padre::Plugin::Cookbook::Recipe03::FBP::AboutFB;

# This module was generated by Padre::Plugin::FormBuilder::PerlX.
# To change this module, edit the original .fbp file and regenerate.
# DO NOT MODIFY BY HAND!

use 5.010;
use strict;
use warnings;
use diagnostics;
use utf8;
use autodie;
use Padre::Wx             ();
use Padre::Wx::Role::Main ();

use version; our $VERSION = qv(0.14);
use parent-norequire, qw(
	Padre::Wx::Role::Main
	Wx::Dialog
);

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new(
		$parent,
		-1,
		"About",
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_DIALOG_STYLE,
	);

	my $package_name = Wx::StaticText->new(
		$self,
		-1,
		"Padre Plug-in",
	);
	$package_name->SetFont( Wx::Font->new( Wx::wxNORMAL_FONT->GetPointSize, 70, 90, 92, 0, "" ) );

	my $m_staticline1 = Wx::StaticLine->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLI_HORIZONTAL,
	);

	my $name_version = Wx::StaticText->new(
		$self,
		-1,
		"name_version",
	);
	$name_version->SetFont( Wx::Font->new( 14, 70, 90, 90, 0, "" ) );

	my $developed_by = Wx::StaticText->new(
		$self,
		-1,
		"developed_by",
	);

	my $m_staticline2 = Wx::StaticLine->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLI_HORIZONTAL,
	);

	my $credits = Wx::Button->new(
		$self,
		-1,
		"Credits",
	);

	Wx::Event::EVT_BUTTON(
		$self, $credits,
		sub {
			shift->credits_clicked(@_);
		},
	);

	my $licence = Wx::Button->new(
		$self,
		-1,
		"Licence",
	);

	Wx::Event::EVT_BUTTON(
		$self, $licence,
		sub {
			shift->licence_clicked(@_);
		},
	);

	my $close_button = Wx::Button->new(
		$self,
		Wx::wxID_CANCEL,
		"Close",
	);
	$close_button->SetDefault;

	my $m_staticline3 = Wx::StaticLine->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLI_HORIZONTAL,
	);

	my $bSizer2 = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$bSizer2->Add( $package_name, 1, Wx::wxALL, 5 );

	my $bSizer3 = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$bSizer3->Add( $name_version, 0, Wx::wxALIGN_CENTER | Wx::wxALL, 5 );
	$bSizer3->Add( $developed_by, 0, Wx::wxALIGN_CENTER | Wx::wxALL, 5 );

	my $bSizer4 = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$bSizer4->Add( $credits,      0, Wx::wxALL, 3 );
	$bSizer4->Add( $licence,      0, Wx::wxALL, 3 );
	$bSizer4->Add( $close_button, 0, Wx::wxALL, 3 );

	my $bSizer1 = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$bSizer1->Add( $bSizer2,       0, Wx::wxEXPAND,             5 );
	$bSizer1->Add( $m_staticline1, 0, Wx::wxEXPAND | Wx::wxALL, 3 );
	$bSizer1->Add( $bSizer3,       1, Wx::wxEXPAND,             5 );
	$bSizer1->Add( $m_staticline2, 0, Wx::wxEXPAND | Wx::wxALL, 3 );
	$bSizer1->Add( $bSizer4,       0, Wx::wxEXPAND,             5 );
	$bSizer1->Add( $m_staticline3, 0, Wx::wxEXPAND | Wx::wxALL, 3 );

	$self->SetSizer($bSizer1);
	$self->Layout;
	$bSizer1->Fit($self);

	$self->{package_name} = $package_name->GetId;
	$self->{name_version} = $name_version->GetId;
	$self->{developed_by} = $developed_by->GetId;

	return $self;
}

=pod
 
=over 4
 
=item package_name ()
 
Public Accessor package_name Auto-generated.
 
=back
 
=cut

sub package_name {
	my $self = shift;
	return Wx::Window::FindWindowById( $self->{package_name} );
}

=pod
 
=over 4
 
=item name_version ()
 
Public Accessor name_version Auto-generated.
 
=back
 
=cut

sub name_version {
	my $self = shift;
	return Wx::Window::FindWindowById( $self->{name_version} );
}

=pod
 
=over 4
 
=item developed_by ()
 
Public Accessor developed_by Auto-generated.
 
=back
 
=cut

sub developed_by {
	my $self = shift;
	return Wx::Window::FindWindowById( $self->{developed_by} );
}

=pod
 
=over 4
 
=item credits_clicked ()
 
Event Handler for credits.OnButtonClick (Required). Auto-generated.
You must implement this Method in your calling class.
 
=back
 
=cut

sub credits_clicked {
	my $self = shift;
	return $self->main->error('Handler method credits_clicked for event credits.OnButtonClick not implemented');
}

=pod
 
=over 4
 
=item licence_clicked ()
 
Event Handler for licence.OnButtonClick (Required). Auto-generated.
You must implement this Method in your calling class.
 
=back
 
=cut

sub licence_clicked {
	my $self = shift;
	return $self->main->error('Handler method licence_clicked for event licence.OnButtonClick not implemented');
}

1;

=pod

=over 4

=item new ()

Constructor. Auto-generated by Padre::Plugin::FormBuilder.

=back

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Padre>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2011 The Padre development team as listed in Padre.pm.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


