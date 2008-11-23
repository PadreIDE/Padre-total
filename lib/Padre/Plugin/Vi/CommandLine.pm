package Padre::Plugin::Vi::CommandLine;

use warnings;
use strict;

use Cwd              ();
use Wx::Perl::Dialog ();
use Padre::Wx        ();
use File::Spec       ();
use File::Basename   ();

=head1 NAME

Padre::Plugin::Vi::CommandLine - vi plugin in Padre ?

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.18';

=head1 SYNOPSIS

Install L<Padre>, install this plug-in. 

=head1 DESCRIPTION

B<WARNING> The module is still experimental B<WARNING>

When you select the menu item or press the hot-key you should see a new window with
a place to enter text and an OK and Cancel buttons.

The text entry place is sort-of a command line.

Currently available commands are based on the vi command mode.

=over 4

=item e path/to/file

open a file for editing supports TAB completion

=item w

write a file

It does NOT support save-as or providing filename.

=back

=cut

my @layout =  (
	[
		['Wx::TextCtrl', 'entry', ''],
		['Wx::Button',     'ok',     Wx::wxID_OK], 
		['Wx::Button',     'cancel', Wx::wxID_CANCEL],
	]
);
my $tab_started;
my $last_tab;
my $dialog;

sub dialog {
	my ($class) = @_;
	
	my $main   = Padre->ide->wx->main_window;
	if (not $dialog) {
		$dialog = Padre::Wx::Dialog->new(
			parent   => $main->{notebook},
			title    => "Command Line",
			layout   => \@layout,
			width    => [500],
		);
		$dialog->{_widgets_}{entry}->SetFocus;
		$dialog->{_widgets_}{ok}->SetDefault;
		Wx::Event::EVT_CHAR( $dialog->{_widgets_}{entry}, \&on_key_pressed );
	}

	return $dialog;
}

sub show_prompt {
	my ($class) = @_;
	my $main   = Padre->ide->wx->main_window;
	my $dialog = $class->dialog();

#	print "Pos: ", join ":", $main->{notebook}->GetScreenPosition, "\n";
#	print "Size: ", join ":", $main->{notebook}->GetSizeWH, "\n";
	$dialog->{_widgets_}{entry}->SetValue('');
	#$dialog->SetPosition($main->{notebook}->GetScreenPosition);
	my $ret = $dialog->ShowModal;
	if ( $ret eq Wx::wxID_CANCEL ) {
		#$dialog->Hide;
		return;
	}
	
	my $cmd = $dialog->{_widgets_}{entry}->GetValue;
	if ($cmd =~ /^e\s+(.*)/ and defined $1) {
		my $file = $1;
		# try to open file
		$main->setup_editor(File::Spec->catfile(Padre->ide->{original_dir}, $file));
		$main->refresh_all;
	} elsif ($cmd eq 'w') {
		# save file
		$main->on_save;
	} elsif ($cmd =~ /^\d+$/) {
		Padre->ide->wx->main_window->selected_editor->GotoLine($cmd-1);
	}
	
	return;
}

my @commands = qw(e w);
my @current_options;

sub on_key_pressed {
	my ($text_ctrl, $event) = @_;
	my $mod  = $event->GetModifiers || 0;
	my $code = $event->GetKeyCode;

	# remove the bit ( Wx::wxMOD_META) set by Num Lock being pressed on Linux
	$mod = $mod & (Wx::wxMOD_ALT() + Wx::wxMOD_CMD() + Wx::wxMOD_SHIFT());
	
	if ($code != Wx::WXK_TAB) {
		$tab_started = undef;
		$event->Skip(1);
		return;
	}

	my $txt = $text_ctrl->GetValue;
	$txt = '' if not defined $txt; # just in case...
	if (not defined $tab_started) {
		$last_tab    = '';
		$tab_started = $txt;

		# setup the loop
		if ($tab_started eq '') {
			@current_options = @commands;
		} elsif ($tab_started =~ /^e\s+(.*)$/) {
			my $prefix = $1;
			my $path = Padre->ide->{original_dir};
			if ($prefix) {
				if (File::Spec->file_name_is_absolute( $prefix ) ) {
					$path = $prefix;
				} else {
					$path = File::Spec->catfile($path, $prefix);
				}
			}
			$prefix = '';
			my $dir = $path;
			if (-e $path) {
				if (-f $path) {
					return;
				} elsif (-d $path) {
					$dir = $path;
					$prefix = '';
					# go ahead, opening the directory
				} else {
					# what shall we do here?
					return;
				}
			} else { # partial file or directory name
				$dir     = File::Basename::dirname($path);
				$prefix  = File::Basename::basename($path);
			}
			if (opendir my $dh, $dir) {
				@current_options = sort
							map {-d "$prefix$_" ? "$_/" : $_} 
							map  { $_ =~ s/^$prefix//; $_ }
							grep { $_ =~ /^$prefix/ }
							grep {$_ ne '.' and $_ ne '..'} readdir $dh;
			}
		} else {
			@current_options = ();
		}
	}
	return if not @current_options; # somehow alert the user?
	
	my $option;
	if ( $mod == Wx::wxMOD_SHIFT() ) {
		if ($last_tab eq 'for') {
			unshift @current_options, pop @current_options
		}
		$option = pop @current_options;
		unshift @current_options, $option;
		$last_tab = 'back';
	} else {
		if ($last_tab eq 'back') {
			push @current_options, shift @current_options;
		}
		$option = shift @current_options;
		push @current_options, $option;
		$last_tab = 'for';
	}

	$text_ctrl->SetValue($tab_started . $option);
	$text_ctrl->SetInsertionPointEnd;

	$event->Skip(0);
	return;
}


sub about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::CommandLine");
	$about->SetDescription(
		"Experimental vi-like command line\n"
	);
	#$about->SetVersion($Padre::VERSION);
	Wx::AboutBox( $about );
	return;
}

=head1 AUTHOR

Gabor Szabo, C<< <szabgab at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to  L<http://padre.perlide.org/>. 
I will be notified, and then you'll automatically be notified of progress on your 
bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Padre::Plugin::CommandLine


You can also look for information at: 

L<http://padre.perlide.org/>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Gabor Szabo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
