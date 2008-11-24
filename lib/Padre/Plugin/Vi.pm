package Padre::Plugin::Vi;
use strict;
use warnings;

use base 'Padre::Plugin';

use Scalar::Util qw(refaddr);

our $VERSION = '0.18';

=head1 NAME

Padre::Plugin::Vi - vi keyboard for Padre

=head1 DESCRIPTION

Once installed and enabled the user is in full vi-emulation mode,
which was partially implemented.

The 3 basic modes of vi are in development:

When you turn on vi-mode, or load Padre with vi-mode already enabled
you reach the normal navigation mode of vi.

We don't plan to impelement many of the configuration options of vi. 
Even parts that are going to be implemented will not use the same method
of configuration.

That said, we are planning to add looking for vi configuration options in
the source file so the editor can set its own configuration based on the
vi configuration options.


The following are implemented:

=head2 Navigation mode

=over

=item *

in navigation mode catch ':' and open the command line

=ietm *

l,h,k,j  - (right, left, up, down) navigation 

4 arrows also work

Number prefix are alloed in both the 4 letter and the 4 arrows

=item *

PageUp, PageDown

=item *

Home - goto first character on line

=item *

End - goto last character on line

=item *

v - visual mode, to start marking section

TODO - ENTER should yank the data, other operation that should work on the selection?

=item *

p - paste below

P - paste above

=item *

Ctrl-6 - jump to last window edited. (This is inherited from Padre)

=item *

a - switch to insert mode after the current character

=item *

i - switch to insert mode before the current character

TODO this is currently step one character back as the caret is not
ON a caracter but between two.

=item *

o - add an empty line below current line and switch to insert mode

O - add an empty line above current line and switch to insert mode

=item *

x - delete current character

Nx - delete N characters

=item *

dd - delete current line

Ndd - (N any number) delete N lines

=item *

yy - yank (copy) current line to buffer

Nyy - yank (copy) N lines to buffer

TODO yy - should not mark the text that is yanked or should remove the selection

=item *

u - undu last editing

=item *

J - (shift-j) join lines, join the next line after the current one

=item *

^ - (shift-6) jump to beginning of line

=item *

$ - (shift-4) jump to end of line

=back

=head2 Insert mode

=over 4

=item *

ESC moves to navigation mode

=item *

Ctrl-p - autocompletion (inherited from Padre)

=back

=head2 Command mode

=over 4

=item *

w - write current buffer

=item *

e filename - open file for editing

TAB completition of directory and filenames

TODO: it seems the auto completition does not always (or not at all?)
put the trailing / on directory names

=item *

:42 - goto line 42 

(we have it in generalized form, you can type any number there :)

=item *

42G - jump to line 42

G - jump to last line

=back

=head1 TODO

Better indication that Padre is  in vi-mode.

Change the cursor for navigation mode and back to insert mode.
(fix i)

Integrate command line pop-up
move it to the bottom of the window
make it come up faster (show/hide instead of create/destroy?)
(maybe actually we should have it integrated it into the main GUI
and add it as another window under or above the output window?)
Most importantly, make it faster to come up


:q - exit

:wq - write and exit

/ and search connect it to the new (and yet experimental search)

:d$ - delete till end of line
:dw - delete word


if ($buffer =~ /^(\d*)([lkjhxaiup])$/ or
    $buffer =~ /^(\d*)(d[dw])$/ or
	$buffer =~ /^(\d*)(y[yw])$/) {
	process($1, $2);
}

:ZZ
:q!
:e!
:ls and :b2 to switch buffer


=cut

sub padre_interfaces {
	'Padre::Plugin' => 0.18,
}

sub plugin_enable {
	my ($self) = @_;

	require Padre::Plugin::Vi::Editor;
	require Padre::Plugin::Vi::CommandLine;
#	foreach my $editor ( Padre->ide->wx->main_window->pages ) {
#		$self->editor_enable($editor);
#	}
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

sub menu_plugins_simple {
	return ("Vi mode" => ['About' => \&about ]);
}

sub about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Vi");
	$about->SetDescription(
		"Try to emulate the vi modes of operation\n"
	);
	$about->SetVersion($Padre::Plugin::Vi::VERSION);
	$about->SetCopyright(Wx::gettext("Copyright 2008 Gabor Szabo"));
	# Only Unix/GTK native about box supports websites
	if ( Padre::Util::UNIX ) {
		$about->SetWebSite("http://padre.perlide.org/");
	}
	$about->AddDeveloper("Gabor Szabo");

	Wx::AboutBox( $about );
	return;
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
