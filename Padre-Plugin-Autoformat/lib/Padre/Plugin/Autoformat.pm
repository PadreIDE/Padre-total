package Padre::Plugin::Autoformat;

# ABSTRACT: Reformats your text within Padre

use strict;
use warnings;

use Padre::Plugin;
use Padre::Util;
use Padre::Wx;

use File::Basename qw{ fileparse };
use File::Spec::Functions qw{ catfile };
use base qw{ Padre::Plugin };

our $VERSION = '1.25';

# -- padre plugin api, refer to Padre::Plugin
#######
# Define Plugin Name required
#######
sub plugin_name {
	return Wx::gettext('Autoformat');
}

# plugin icon
sub plugin_icon {

	# find icon path using Padre API
	my $dir = File::Spec->catdir( Padre::Util::share('Autoformat'), 'icons' );
	my $icon_file = File::Spec->catfile( $dir, 'justify.png' );

	# create and return icon
	return Wx::Bitmap->new( $icon_file, Wx::wxBITMAP_TYPE_PNG );
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
	my ($self) = @_;
	Wx::gettext('Autoformat') => [

		#'About'                    => 'show_about',
		Wx::gettext("Autoformat\tCtrl+Shift+J") => 'autoformat',
	];
}


# -- public methods

sub autoformat {
	my ($self) = @_;

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

#######
# Clean up dialog Main, Padre::Plugin,
#######
sub plugin_disable {
	my $self = shift;

	$self->SUPER::plugin_disable(@_);

	return 1;

}


1;
__END__

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

Plugin icon courtesy of Mark James, at
L<http://www.famfamfam.com/lab/icons/silk/>.

You can also look for information on this module at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-Autoformat>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-Autoformat>

=item * Open bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-Autoformat>

=back

=cut
