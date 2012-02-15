package Padre::Plugin::Moose;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.02';

use Padre::Plugin ();

our @ISA = 'Padre::Plugin';

######################################################################
# Padre Integration

sub padre_interfaces {
    'Padre::Plugin' => 0.94;
}

######################################################################
# Padre::Plugin Methods

sub plugin_name {
    Wx::gettext('Moose');
}

sub plugin_disable {
    require Padre::Unload;
    Padre::Unload->unload('Padre::Plugin::Moose');
    Padre::Unload->unload('Padre::Plugin::Moose::Main');
    Padre::Unload->unload('Moose');
}

# The command structure to show in the Plugins menu
sub menu_plugins {
    my $self = shift;
    my $main = $self->main;
    my $menu_item =
      Wx::MenuItem->new( undef, -1, $self->plugin_name . "...\tF8", );
    Wx::Event::EVT_MENU(
        $main,
        $menu_item,
        sub {
            eval {
                require Padre::Plugin::Moose::Main;
                Padre::Plugin::Moose::Main->new($main)->Show;
            };
            print "Error: $@" if $@;
        },
    );

    return $menu_item;

    # [
    # Wx::gettext('New Class...') => sub {
    # require Padre::Plugin::Moose::FBP::NewClass;
    # Padre::Plugin::Moose::FBP::NewClass->new($main)->Show;
    # return;
    # },
    # Wx::gettext('New Role...') => sub {
    # require Padre::Plugin::Moose::FBP::NewRole;
    # Padre::Plugin::Moose::FBP::NewRole->new($main)->Show;
    # return;
    # },
    # Wx::gettext('New Subtype...') => sub {
    # require Padre::Plugin::Moose::FBP::NewSubType;
    # Padre::Plugin::Moose::FBP::NewSubType->new($main)->Show;
    # return;
    # },
    # Wx::gettext('New Attribute...') => sub {
    # require Padre::Plugin::Moose::FBP::NewAttribute;
    # Padre::Plugin::Moose::FBP::NewAttribute->new($main)->Show;
    # return;
    # },

    # '---' => undef,

    # Wx::gettext('Online References') => [
    # Wx::gettext('Manual') => sub {
    # Padre::Wx::launch_browser('https://metacpan.org/module/Moose::Manual');
    # },
    # Wx::gettext('How to cook a Moose?') => sub {
    # Padre::Wx::launch_browser('https://metacpan.org/module/Moose::Cookbook');
    # },
    # Wx::gettext('Website') => sub {
    # Padre::Wx::launch_browser('http://moose.iinteractive.com/');
    # },
    # Wx::gettext('Community Live Support') => sub {
    # Padre::Wx::launch_irc( 'irc.perl.org' => 'moose' );
    # },
    # ],

    # '---' => undef,

    # Wx::gettext('About') => sub {
    # $self->on_show_about;
    # },
    # ];
}

sub on_show_about {
    require Moose;
    require Padre::Unload;
    my $about = Wx::AboutDialogInfo->new;
    $about->SetName('Padre::Plugin::Moose');
    $about->SetDescription(
        Wx::gettext('Moose support for Padre') . "\n\n"
          . sprintf(
            Wx::gettext('This system is running Moose version %s'),
            $Moose::VERSION
          )
          . "\n"
    );
    $about->SetVersion($Padre::Plugin::Moose::VERSION);
    Padre::Unload->unload('Moose');
    Wx::AboutBox($about);
    return;
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

=head2 'New Moose Class'

This options lets you create a new Moose application.

=head2 Moose Online References

This menu option contains a series of external reference links on Moose. Clicking on each of them will point your default web browser to their websites.

=head2 About

Shows a nice about box with this module's name and version.

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

This software is copyright (c) 2010 by Breno G. de Oliveira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
