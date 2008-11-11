package Padre::Plugin::CommandLine;

use warnings;
use strict;

use Cwd              ();
use Wx::Perl::Dialog ();
use Padre::Wx        ();


=head1 NAME

Padre::Plugin::CommandLine - vi in Padre ?

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Install L<Padre>, install this plug-in. It should automatically 
a menu option Plugins/CommandLine/Show 
with Alt-` (backtick) as a hot-key. (It will later change or be configurable.

=head1 DESCRIPTION

B<WARNING> The module is still experimental B<WARNING>

When you select the menu item or press the hot-key you should see a new window with
a place to enter text and an OK and Cancel buttons.

The text entry place is sort-of a command line.

Currently available commands are based on the vi command mode.

=over 4

=item e path/to/file

open a file for editing

=item w

write a file

=back

=head1 FUNCTIONS

=cut

my @menu = (
    ["About",        \&about],
    ["Go\tAlt-`",     \&go],
);

sub menu {
    my ($self) = @_;
    return @menu;
}


my @layout =  (
	[
		['Wx::TextCtrl', 'entry', ''],
		['Wx::Button',     'ok',     Wx::wxID_OK], 
		['Wx::Button',     'cancel', Wx::wxID_CANCEL],
	]
);


my $tab_started;
sub go {
	my $main   = Padre->ide->wx->main_window;
	my $dialog = Padre::Wx::Dialog->new(
		parent   => $main,
		title    => "Command Line",
		layout   => \@layout,
		width    => [500],
	);
	$dialog->{_widgets_}{entry}->SetFocus;
	$dialog->{_widgets_}{ok}->SetDefault;
	my @commands = qw(e w);
	my @current_options;
	Wx::Event::EVT_CHAR( $dialog->{_widgets_}{entry}, sub {
		my ($text_ctrl, $event) = @_;
		my $mod  = $event->GetModifiers || 0;
		my $code = $event->GetKeyCode;
		if ($code != Wx::WXK_TAB) {
			$tab_started = undef;
			$event->Skip(1);
			return;
		}

		my $txt = $text_ctrl->GetValue;
		$txt = '' if not defined $txt; # just in case...
		if (not defined $tab_started) {
			$tab_started = $txt;
			
			# setup the loop
			if ($tab_started eq '') {
				@current_options = @commands;
			} elsif ($tab_started =~ /^e\s+(.*)$/) {
				my $prefix = $1;
				my $cwd = Cwd::cwd();
				#msg($cwd);
				if ($prefix) {
					$cwd = File::Spec->catfile($cwd, $prefix);
				}
				if (opendir my $dh, $cwd) {
					@current_options = map {-d $_ ? "$_/" : $_} grep {$_ ne '.' and $_ ne '..'} readdir $dh;
					#@current_options = readdir $dh;
				}
				#msg (join ':', @current_options);
			} else {
				@current_options = ();
			}
		}
		return if not @current_options; # somehow alert the user?
		my $option = shift @current_options;
		push @current_options, $option;

		$text_ctrl->SetValue($tab_started . $option);
		$text_ctrl->SetInsertionPointEnd;

		$event->Skip(0);
		return;
		} );


	if ($dialog->show_modal) {
		my $cmd = $dialog->{_widgets_}{entry}->GetValue;
		if ($cmd =~ /^e\s+(.*)/ and defined $1) {
			my $file = $1;
			# try to open file
 			$main->setup_editor($file);
			$main->refresh_all;
		} elsif ($cmd eq 'w') {
			# save file
			$main->on_save;
		}
	}
	$dialog->Destroy;
	
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

=head1 COPYRIGHT & LICENSE

Copyright 2008 Gabor Szabo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
