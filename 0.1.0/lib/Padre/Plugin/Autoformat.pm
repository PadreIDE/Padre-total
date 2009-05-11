#
# This file is part of Padre::Plugin::Autoformat.
# Copyright (c) 2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Padre::Plugin::Autoformat;

use strict;
use warnings;

use base qw{ Padre::Plugin };

our $VERSION = '0.1.0';


# -- padre plugin api, refer to Padre::Plugin

# plugin name
sub plugin_name { 'Autformat' }

# padre interface
sub padre_interface {
    'Padre::Plugin' => 0.28,
}

# plugin menu.
sub menu_plugins_simple {
    my ($self) = @_;
    'Autoformat' => [
        #'About'                    => 'show_about',
        "Autoformat\tCtrl+Shift+J" => 'autoformat',
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

    my $selected = $editor->GetSelectedText;
    return unless $selected;

    require Text::Autoformat;
    my $reformatted = Text::Autoformat::autoformat($selected);

    $editor->ReplaceSelection($reformatted);
}

1;
__END__

=head1 NAME

Padre::Plugin::Autoformat - reformat your text within Padre



=head1 SYNOPSIS

    $ padre
    Ctrl+Shift+J



=head1 DESCRIPTION

This plugin allows one to reformat her text automatically with Ctrl+Shift+J.
It is using C<Text::Autoformat> underneath, so check this module's pod for
more information.


=head1 PUBLIC METHODS

=head2 Standard Padre::Plugin API

C<Padre::Plugin::Autoformat> defines a plugin which follows C<Padre::Plugin>
API. Refer to this module's documentation for more information.

The following methods are implemented:

=over 4

=item menu_plugins_simple()

=item padre_interface()

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

Our git repository is located at L<git://repo.or.cz/padre-plugin-autoformat.git>,
and can be browsed at L<http://repo.or.cz/w/padre-plugin-autoformat.git>.


You can also look for information on this module at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-Autoformat>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-Autoformat>

=item * Open bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-Autoformat>

=back



=head1 AUTHOR

Jerome Quelin, C<< <jquelin@cpan.org> >>



=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 Jerome Quelin, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
