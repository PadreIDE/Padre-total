package Padre::Plugin::Autoformat;

use strict;
use warnings;

use Padre::Plugin ();
use Padre::Util   ();
use Padre::Wx     ();

use File::Spec ();
use base qw{ Padre::Plugin };

our $VERSION = '1.23';

# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::Autoformat
};

# -- padre plugin api, refer to Padre::Plugin
#######
# Define Plugin Name required
#######
sub plugin_name {
	return Wx::gettext('Autoformat');
}

#######
# Define Padre Interfaces required
#######
sub padre_interfaces {
	return (
		'Padre::Plugin'     => 0.94,
		'Padre::Wx::Editor' => 0.94,
	);
}

# plugin menu.
sub menu_plugins_simple {
	my $self = shift;
	Wx::gettext('Autoformat') => [

		Wx::gettext("Autoformat") . "\tCtrl+Shift+J" => sub { $self->autoformat },
		Wx::gettext('About')                         => sub { $self->show_about },
	];
}


# -- public methods

sub autoformat {
	my $self = shift;

	my $main     = $self->main;
	my $current  = $main->current;
	my $document = $current->document;
	my $editor   = $current->editor;
	return unless $editor;

	# no selection means autoformat current paragraph
	if ( not $editor->GetSelectedText ) {
		my ( $b, $e ) = $editor->current_paragraph;
		return if $b == $e; # in between paragraphs
		$editor->SetSelection( $b, $e );
	}

	require Text::Autoformat;
	my $messy  = $editor->GetSelectedText;
	my $tidied = Text::Autoformat::autoformat($messy);
	$editor->ReplaceSelection($tidied);
}

sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName( Wx::gettext('Autoformat Plug-in') );
	my $authors     = 'Jerome Quelin';
	my $description = Wx::gettext( <<'END' );
Text Autoformat support for Padre

Copyright 2010-2012 %s
This plug-in is free software; you can redistribute it and/or modify it under the same terms as Padre.
END
	$about->SetDescription( sprintf( $description, $authors ) );

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}

#######
# Clean up dialog Main, Padre::Plugin,
#######
sub plugin_disable {

	# TODO: Switch to Padre::Unload once Padre 0.96 is released
	for my $package (CHILDREN) {
		require Padre::Unload;
		Padre::Unload->unload($package);
	}

	return 1;

}


1;
__END__

=head1 NAME

Padre::Plugin::Autoformat - Reformats your text within Padre

=head1 SYNOPSIS

    $ padre
    Ctrl+Shift+J

=head1 DESCRIPTION

This plugin allows one to reformat her text automatically with Ctrl+Shift+J.
It is using C<Text::Autoformat> underneath, so check this module's pod for
more information.


=head1 PUBLIC METHODS

=head2 Standard Padre::Plugin API

L<Padre::Plugin::Autoformat> defines a plugin which follows L<Padre::Plugin>
API. Refer to this module's documentation for more information.

The following methods are implemented:

=over 4

=item menu_plugins_simple()

=item padre_interfaces()

=item plugin_icon()

=item plugin_name()

=back


=head2 Formatting methods

=over 4

=item * autoformat()

Replace the current selection with its autoformatted content.

=back

=head1 BUGS

Please report any bugs or feature requests to C<padre-plugin-autoformat at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-Autoformat>. I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<Text::Autoformat>
=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-Autoformat>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-Autoformat>

=item * Open bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-Autoformat>

=back

=head1 AUTHORS

Jerome Quelin <jquelin@gmail.com>

=head1 CONTRIBUTORS

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010-2012 by Jerome Quelin

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
