package Wx::Perl::Dialog::Simple;

=pod

=head1 NAME

Wx::Perl::Dialog::Simple - a set of simple dialogs (a partial Zenity clone in wxPerl)

=head1 SYNOPSIS

As a module:

  use Wx::Perl::Dialog::Simple;

  my $name = entry(title => "What is your name?");
  message(text => "How are you $name today?\n");

On the command line try

  wxer --help

=head1 General Options

There are some common option for every dialog

title

window-icon  NA

width        NA

height       NA

=head1 METHODS

Dialogs

=head2 entry

Display a text entry dialog

=cut

use 5.008;
use strict;
use warnings;
use Cwd        ();
use Exporter   ();
use File::Spec ();

our $VERSION = '0.52';
our @ISA     = 'Exporter';

# I'd change this, but I suspect it's rather breaky
our @EXPORT = ## no critic (ProhibitAutomaticExportation)
	qw(
	entry
	password
	file_selector
	dir_selector
	dir_picker
	file_picker
	date_picker
	colour_picker
	choice
	single_choice
	message
	calendar
);

# print_out close_app open_frame display_text

use Wx::Perl::Dialog;
use Wx::STC ();

sub entry {
	my (%args) = @_;

	%args = (
		title   => '',
		prompt  => '',
		default => '',
		%args
	);

	my $class = $args{password} ? 'Wx::PasswordEntryDialog' : 'Wx::TextEntryDialog';
	my $dialog = $class->new( undef, $args{prompt}, $args{title}, $args{default} );
	if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
		return;
	}
	my $resp = $dialog->GetValue;
	$dialog->Destroy;
	return $resp;
}

sub password {
	my (%args) = @_;

	$args{password} = 1;

	return entry(%args);
}

sub file_selector {
	my (%args) = @_;
	%args = (
		title => '',
		%args
	);

	my $dialog = Wx::FileDialog->new( undef, $args{title}, '', "", "*.*", Wx::wxFD_OPEN );
	if ( $^O !~ /win32/i ) {
		$dialog->SetWildcard("*");
	}
	if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
		return;
	}
	my $filename    = $dialog->GetFilename;
	my $default_dir = $dialog->GetDirectory;

	return File::Spec->catfile( $default_dir, $filename );
}

sub dir_selector {
	my (%args) = @_;
	%args = (
		title => '',
		path  => '',
		%args
	);

	my $dialog = Wx::DirDialog->new( undef, $args{title}, $args{path} );
	if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
		return;
	}
	my $dir = $dialog->GetPath;

	return $dir;
}

sub date_picker {

	require Wx::DateTime;
	require Wx::Calendar;
	my $date = Wx::DateTime->newFromDMY( 8, 0, 1979, 1, 1, 1, 1 );
	my $calendar = Wx::DatePickerCtrl->new( undef, -1, $date );

	return dialog(
		sub { Wx::DatePickerCtrl->new( $_[0], -1 ) },
		sub { $_[0]; },
		sub { $_[0]->GetValue->Format; },
		{   title => 'Select date',
		},
	);
}

sub colour_picker {

	return dialog(
		sub { Wx::ColourPickerCtrl->new( $_[0], -1 ) },
		sub { $_[0]; },
		sub { my $c = $_[0]->GetColour; return [ $c->Red, $c->Green, $c->Blue ] },
		{   title => 'Select colour',
		},
	);
}

sub file_picker {
	return dialog(
		sub { Wx::FilePickerCtrl->new( $_[0] ) },
		sub { $_[0]->SetPath( Cwd::cwd() ) },    # setup
		sub { $_[0]->GetPath; },                 # get data
		{   title => 'Select file',
		},
	);
}

sub dir_picker {
	return dialog(
		sub { Wx::DirPickerCtrl->new( $_[0] ) },
		sub { $_[0]->SetPath( Cwd::cwd() ) },    # setup
		sub { $_[0]->GetPath; },                 # get data
		{   title => 'Select directory',
		},
	);
}

=pod

=head2 dialog

Generic dialog, with two buttons and a place for some control.
It needs 4 parameters: 3 subroutines and a hash-ref

  dialog(
      sub { create_and_return_the_control },
      sub { setup_data_in_the control },
      sub { fetch_and_return_data_from_the_control },
      {
          title => "",
          other arguments,
      }
  );

=cut

sub dialog {
	my ( $control, $setup, $getdata, $args ) = @_;

	$args ||= {};
	$args->{title} ||= '';

	my $dialog = Wx::Dialog->new( undef, -1, $args->{title} );
	my $ctrl   = $control->($dialog);
	my $ok     = Wx::Button->new( $dialog, Wx::wxID_OK, '' );
	my $cancel = Wx::Button->new( $dialog, Wx::wxID_CANCEL, '', [ -1, -1 ], $ok->GetSize );

	my $box     = Wx::BoxSizer->new(Wx::wxVERTICAL);
	my $top     = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	my $buttons = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$box->Add($top);
	$box->Add($buttons);
	$top->Add($ctrl);
	$buttons->Add($ok);
	$buttons->Add($cancel);
	$ok->SetDefault;
	$dialog->SetSizer($box);

	my ( $bw, $bh ) = $ok->GetSizeWH;
	my ( $w,  $h )  = $ctrl->GetSizeWH;
	$dialog->SetSize( $bw * 2, $h + $bh + 20 );

	$setup->($ctrl);

	if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
		return;
	}

	my $data = $getdata->($ctrl);

	$dialog->Destroy;

	return $data;
}

sub choice {
	my (%args) = @_;
	%args = (
		title   => '',
		message => '',
		choices => [],

		%args
	);

	my $dialog = Wx::MultiChoiceDialog->new( undef, $args{message}, $args{title}, $args{choices} );
	if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
		return;
	}
	return map { $args{choices}[$_] } $dialog->GetSelections;
}

sub single_choice {
	my (%args) = @_;
	%args = (
		title   => '',
		message => '',
		choices => [],

		%args
	);

	my $dialog = Wx::SingleChoiceDialog->new( undef, $args{message}, $args{title}, $args{choices} );
	if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
		return;
	}
	return $args{choices}[ $dialog->GetSelection ];
}

#=head2 print_out
#
#=cut

#sub print_out {
#    my ($output, $text) = @_;
#    $output->AddText($text);
#    #$Wx::Perl::Dialog::Simple::app->Yield;
#    return;
#}
#

sub message {
	my (%args) = @_;

	%args = (
		title => '',
		text  => '',

		%args
	);

	Wx::MessageBox( $args{text}, $args{title}, Wx::wxOK | Wx::wxCENTRE );

	return;
}

1;

=pod

=head1 SUPPORT

See L<http://padre.perlide.org/>

=head1 COPYRIGHT

Copyright 2008 Gábor Szabó. L<http://www.szabgab.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=head1 WARRANTY

There is no warranty whatsoever.
If you lose data or your hair because of this program,
that's your problem.

=head1 CREDITS and THANKS

To Mattia Barbon for providing wxPerl.

The idea was taken from the Zenity project.

=cut

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
