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
	Padre::Plugin::Moose::Preferences
	Padre::Plugin::Moose::FBP::Main
	Padre::Plugin::Moose::FBP::Preferences
};





######################################################################
# Padre Integration

sub padre_interfaces {
	'Padre::Plugin'               => 0.94,
		'Padre::Document'         => 0.94,
		'Padre::Wx::Main'         => 0.94,
		'Padre::Wx::Theme'        => 0.94,
		'Padre::Wx::Editor'       => 0.94,
		'Padre::Wx::Role::Main'   => 0.94,
		'Padre::Wx::Role::Dialog' => 0.94,
		;
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
	for my $package (CHILDREN) {
		require Padre::Unload;
		Padre::Unload->unload($package);
	}
}

sub menu_plugins_simple {
	my $self = shift;
	return Wx::gettext('Moose') => [
		Wx::gettext("Designer\tF8") => sub { print "before\n"; $self->show_designer; print "after\n";},
		Wx::gettext('Preferences')  => sub { $self->plugin_preferences; },
	];
}

# Plugin preferences
sub plugin_preferences {
	my $self = shift;

	require Padre::Plugin::Moose::Preferences;
	my $dialog = Padre::Plugin::Moose::Preferences->new( $self->main );
	$dialog->ShowModal;

	return;
}


######################################################################
# Support Methods

sub show_designer {
	my $self = shift;

	eval {
		unless (defined $self->{dialog}) {
			require Padre::Plugin::Moose::Main;
			$self->{dialog} = Padre::Plugin::Moose::Main->new( $self->main );
			$self->{dialog}->run;
		}
	};
	if ($@) {
		$self->main->error( sprintf( Wx::gettext('Error: %s'), $@ ) );
	}

	return;
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Moose - Moose, Mouse and MooseX::Declare support for Padre

=head1 SYNOPSIS

    cpan Padre::Plugin::Moose;

Then use it via L<Padre>, The Perl IDE. Press F8.

=head1 DESCRIPTION

Once you enable this Plugin under Padre, you'll get a brand new menu with the following options:

=head2 Moose Designer

Opens up a user-friendly dialog where you can add classes, roles, attributes, subtypes and methods.
The dialog contains a tree of class/role elements that are created while it is open and a preview of
generated Perl code. It also contains links to Moose manual, cookbook and website.

=head2 Moose Preferences

TODO describe Moose Preferences

=head2 TextMate-style TAB triggered snippets

TODO describe TextMate-style TAB triggered snippets

=head2 Keyword Syntax Highlighting

TODO describe Keyword Syntax Highlighting

=head1 BUGS

Please report any bugs or feature requests to C<bug-padre-plugin-moose at rt.cpan.org>, or through
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

=head1 CONTRIBUTORS

=over 4

=item *

Adam Kennedy <adamk@cpan.org>

=back


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ahmad M. Zawawi

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
