package Padre::Plugin::Vi;
use strict;
use warnings;

use base 'Padre::Plugin';

use Scalar::Util qw(refaddr);

our $VERSION = '0.17';

=head1 NAME

Padre::Plugin::Vi - vi keyboard for Padre

=head1 DESCRIPTION

Once installed and enabled the user is in full vi-emulation mode,
which was partially implemented.

The 3 basic modes of vi are in development:

When you turn on vi-mode, or load Padre with vi-mode already enabled
you reach the normal navigation mode of vi.



In general the following are implemented:

=over

=item *

in naviation mode catch 'a' and move to insert mode

=item *

in insert mode catch ESC and move to navigation mode

=item *

in navigation mode catch 'd' character and delete the current charcter

=item *

in navigation mode catch '3d' and delete 3 characters

=item *

in navigation mode catch ':' and open the command line

=item *

menu option to swicth back and force vi-mode

=back

We don't plan to impelement many of the configuration options of vi. 
Even parts that are going to be implemented will not use the same method
of configuration.

That said, we are planning to add looking for vi configuration options in
the source file so the editor can set its own configuration based on the
vi configuration options.

=cut

sub padre_interfaces {
	'Padre::Plugin' => 0.17,
}

sub plugin_enable {
	my ($self) = @_;

	require Padre::Plugin::Vi::Editor;
	require Padre::Plugin::Vi::CommandLine;
	foreach my $editor ( Padre->ide->wx->main_window->pages ) {
		$self->editor_enable($editor);
	}
}

sub plugin_disable {
	my ($self) = @_;

	foreach my $editor ( Padre->ide->wx->main_window->pages ) {
		$self->editor_stop($editor);
	}
	delete $INC{"Padre/Plugin/Vi/Editor.pm"};
	delete $INC{"Padre/Plugin/Vi/CommandLine.pm"};
	return;
}

sub editor_enable {
	my ($self, $editor, $doc) = @_;
	
	$self->{editor}{refaddr $editor} = Padre::Plugin::Vi::Editor->new($editor);

	Wx::Event::EVT_KEY_DOWN( $editor, sub { $self->key_down(@_) } );

	return 1;
}

sub editor_stop {
	my ($self, $editor, $doc) = @_;
	
	delete $self->{editor}{refaddr $editor};
	Wx::Event::EVT_KEY_DOWN( $editor, undef );

	return 1;
}

# old way
sub menu {
	return ( 
		['About' => \&about ],
	);
}
# new way
sub menu_plugins_simple {
	return ("Vi mode", ['About' => \&about ]);
}


sub key_down {
	my ($self, $editor, $event) = @_;

	my $mod  = $event->GetModifiers || 0;
	my $code = $event->GetKeyCode;

	my $skip = $self->{editor}{refaddr $editor}->key_down($mod, $code);
	$event->Skip($skip);
	return;
}


1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
