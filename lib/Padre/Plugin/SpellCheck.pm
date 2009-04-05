#
# This file is part of Padre::Plugin::SpellCheck.
# Copyright (c) 2009 Fayland Lam, all rights reserved.
# Copyright (c) 2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Padre::Plugin::SpellCheck;

use warnings;
use strict;

our $VERSION = '0.02';

use base 'Padre::Plugin';
use Padre::Current ();


# -- padre plugin api, refer to Padre::Plugin

# plugin name
sub plugin_name { 'Spell checking' }

# padre interfaces
sub padre_interfaces {
    'Padre::Plugin' => '0.26',
}

# plugin menu.
sub menu_plugins_simple {
    'Spell Check' => [
        'Check spelling' => 'spell_check',
    ];
}


# -- public methods

sub spell_check {
    my ( $self ) = shift;
    
    my $speller;
    eval {
        require Text::Aspell;
        $speller = Text::Aspell->new;
        $speller->set_option('sug-mode', 'fast');
        # TODO, configurable later
        $speller->set_option('lang','en_US');
    };
    if ( $@ ) {
        Padre::Current->main->error( $@ );
        return;
    }
    
    my $src  = Padre::Current->text;
    my $doc  = Padre::Current->document;
    my $text = $src ? $src : $doc->text_get;
    
    Padre::Current->main->show_output(1);
    Padre::Current->main->output->clear;
    my $has_bad = 0;
    
    foreach my $word ( split /\b/, $text ){
        # Skip empty strings and non-spellable words
        next unless defined $word;
        next unless ($word =~ /^\p{L}+$/i);
        next if $speller->check( $word ) || $word =~ /^\d+$/;
        my @suggestions = $speller->suggest( $word );
        Padre::Current->main->output->AppendText("wrong $word, suggest: " . join(', ', @suggestions) . "\n");
        $has_bad = 1;
    }
    
    unless ( $has_bad ) {
        Padre::Current->main->output->AppendText("Everything seems OK around");
    }

    return 1;
}

1;
__END__

=head1 NAME

Padre::Plugin::SpellCheck - check spelling in Padre



=head1 DESCRIPTION

This plugins allows one to checking her text spelling within Padre. It
is using C<Text::Aspell> underneath, so check this module's pod for more
information.

Of course, you need to have the aspell binary and dictionnary installed.



=head1 PUBLIC METHODS

=head2 Standard Padre::Plugin API

C<Padre::Plugin::SpellCheck> defines a plugin which follows
C<Padre::Plugin> API. Refer to this module's documentation for more
information.

The following methods are implemented:

=over 4

=item menu_plugins_simple()

=item padre_interfaces()

=item plugin_name()

=back


=head2 Spell checking methods

=over 4

=item * spell_check()

Spell checks the current selection (or the whole document).

=back



=head1 BUGS

Please report any bugs or feature requests to C<padre-plugin-spellcheck
at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-
SpellCheck>. I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.



=head1 SEE ALSO

Our svn repository is located at L<http://svn.perlide.org/padre/trunk/Padre-Plugin-
SpellCheck>, and can be browsed at L<http://padre.perlide.org/browser/trunk/Padre-Plugin-
SpellCheck>.


You can also look for information on this module at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-SpellCheck>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-SpellCheck>

=item * Open bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-SpellCheck>

=back


Everything aspell related: L<http://aspell.net>.



=head1 AUTHOR

Jerome Quelin, C<< <jquelin@cpan.org> >>

Original version from Fayland Lam, C<< <fayland at gmail.com> >>



=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 Fayland Lam, all rights reserved.

Copyright (c) 2009 Jerome Quelin, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
