package Padre::Plugin::ShellScript;

use strict;
use base 'Padre::Plugin';
use Class::Autouse 'Padre::Document::ShellScript';

# The plugin name to show in the Plugin Manager and menus
sub plugin_name {
    'Shell Script Plugin';
}

# Declare the Padre interfaces this plugin uses
sub padre_interfaces {
    'Padre::Plugin'     => 0,
      'Padre::Document' => 0,
      'Padre::Wx::Main' => 0,
      ;
}

sub registered_documents {
    'application/x-shellscript' => 'Padre::Document::ShellScript',
      ;
}

# The command structure to show in the Plugins menu
sub menu_plugins_simple {
    my $self = shift;
    'Shell Script' => [ Information => sub { $self->info() }, ];
}

sub info {
    my $self = shift;

    # Generate the About dialog
    my $about = Wx::AboutDialogInfo->new;
    $about->SetName("Shell Scripting Plugin");
    $about->SetDescription("Use the Run menu to run and debug shell scripts.");

    # Show the About dialog
    Wx::AboutBox($about);

    return;
}
1;
__END__

=head1 NAME

Padre::Plugin::ShellScript - L<Padre> and ShellScript

=head1 AUTHOR

Claudio Ramirez C<< <padre.claudio@apt-get.be> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Claudio Ramirez all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
