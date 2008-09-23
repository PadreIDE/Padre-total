package Wx::Perl::Dialog;

use 5.008;
use strict;
use warnings;

use base 'Exporter';
use File::Spec;

our $VERSION = '0.01';

$| = 1;

our @EXPORT = qw(
				entry
				password
				file_selector
				dir_selector
				dir_picker
				file_picker
				choice
				single_choice
				message
				calendar
			);
#                 print_out close_app open_frame display_text

use Wx                 qw(:everything);
use Wx::STC            ();
use Wx::Event          qw(:everything);

=head1 NAME

Wx::Perl::Dialog - a set of simple dialogs (a partial Zenity clone in wxPerl)

=head1 SYNOPIS

As a module:

 use Wx::Perl::Dialog;

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

=cut

=head1 METHODS

Dialogs

=head2 entry

Display a text entry dialog

=cut

sub entry {
    my ( %args ) = @_;

    %args = (
              title   => '',
              prompt  => '',
              default => '',
              %args);

    my $class = $args{password} ? 'Wx::PasswordEntryDialog' : 'Wx::TextEntryDialog';
    my $dialog = $class->new( undef, $args{prompt}, $args{title}, $args{default} );
    if ($dialog->ShowModal == wxID_CANCEL) {
        return;
    }
    my $resp = $dialog->GetValue;
    $dialog->Destroy;
    return $resp;
}

=head2 password

=cut

sub password {
    my ( %args ) = @_;

    $args{password} = 1;
    
    return entry( %args );
}

=head2 file_selector

=cut

sub file_selector {
    my ( %args ) = @_;
    %args = (
                title => '',
                %args);

    my $dialog = Wx::FileDialog->new( undef, $args{title}, '', "", "*.*", wxFD_OPEN);
    if ($^O !~ /win32/i) {
       $dialog->SetWildcard("*");
    }
    if ($dialog->ShowModal == wxID_CANCEL) {
        return;
    }
    my $filename = $dialog->GetFilename;
    my $default_dir = $dialog->GetDirectory;

    return File::Spec->catfile($default_dir, $filename);
}

=head2 dir_selector

=cut

sub dir_selector {
    my ( %args ) = @_;
    %args = (
                title => '',
                path  => '',
                %args);

    my $dialog = Wx::DirDialog->new( undef, $args{title}, $args{path});
    if ($dialog->ShowModal == wxID_CANCEL) {
        return;
    }
    my $dir = $dialog->GetPath;

    return $dir;
}


sub file_picker {
	require Cwd;
	return dialog('Wx::FilePickerCtrl', 
	              sub {$_[0]->SetPath(Cwd::cwd()) }, # setup
	              sub {$_[0]->GetPath; },            # get data
	              title => 'Select file',
	);
}

sub dir_picker {
	require Cwd;
	return dialog('Wx::DirPickerCtrl', 
	              sub {$_[0]->SetPath(Cwd::cwd()) }, # setup
	              sub {$_[0]->GetPath; },            # get data
	              title => 'Select directory',
	);
}

sub dialog {
	my ($control, $setup, $getdata, %args) = @_;

	$args{title} ||= '';

	my $dialog = Wx::Dialog->new( undef, -1, $args{title} );
	my $ctrl   = $control->new( $dialog, -1, "", $args{title} );
	my $ok     = Wx::Button->new( $dialog, wxID_OK, '');
	my $cancel = Wx::Button->new( $dialog, wxID_CANCEL, '', [-1, -1], $ok->GetSize);

	my $box      = Wx::BoxSizer->new(  wxVERTICAL   );
	my $top      = Wx::BoxSizer->new(  wxHORIZONTAL );
    my $buttons  = Wx::BoxSizer->new(  wxHORIZONTAL );
	$box->Add($top);
	$box->Add($buttons);
	$top->Add($ctrl);
	$buttons->Add($ok);
	$buttons->Add($cancel);
	$ok->SetDefault;
	$dialog->SetSizer($box);


	my ($bw, $bh) = $ok->GetSizeWH;
	my ($w, $h)   = $ctrl->GetSizeWH;
	$dialog->SetSize($bw*2, $h+$bh+20);

	$setup->($ctrl);


    if ($dialog->ShowModal == wxID_CANCEL) {
        return;
    }
	
	my $data = $getdata->($ctrl);

	$dialog->Destroy;

    return $data;
}


=head2 choice

=cut

sub choice {
    my ( %args ) = @_;
    %args = (
                title   => '',
                message => '',
                choices => [],

                %args);

    my $dialog = Wx::MultiChoiceDialog->new( undef, $args{message}, $args{title}, $args{choices});
    if ($dialog->ShowModal == wxID_CANCEL) {
        return;
    }
    return map {$args{choices}[$_]} $dialog->GetSelections;
}

sub single_choice {
    my ( %args ) = @_;
    %args = (
                title   => '',
                message => '',
                choices => [],

                %args);

    my $dialog = Wx::SingleChoiceDialog->new( undef, $args{message}, $args{title}, $args{choices});
    if ($dialog->ShowModal == wxID_CANCEL) {
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
#    #$Wx::Perl::Dialog::app->Yield;
#    return;
#}
#

=head2 message

=cut

sub message {
    my ( %args ) = @_;

    %args = (
                title   => '',
                text    => '',

                %args);

    Wx::MessageBox( $args{text}, $args{title}, wxOK|wxCENTRE);

    return;
}

#=head2 calendar
#
#=cut

#sub calendar {
#    my ( %args ) = @_;
#
#    require Wx::Calendar;
#    my $cal = Wx::CalendarCtrl->new();
#    $cal->Show;
#
#    return;
#}
#

#=head2 open_frame
#
#=cut

#sub open_frame {
#    my $frame = Wx::Perl::Dialog::Frame->new;
#    my $output = Wx::StyledTextCtrl->new($frame, -1, [-1, -1], [750, 700]);
#    $output->SetMarginWidth(1, 0);
#    $frame->Show( 1 );
#    return $output;
#}
#
#
#=head2 close_app
#
#=cut

#sub close_app {
##   $frame->Close;
#}
#


#our $main;
#our $app;

=head1 SUPPORT

See L<http://padre.perlide.org/>

=head1 COPYRIGHT

Copyright 2008 Gabor Szabo. L<http://www.szabgab.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=head1 WARRANTY

There is no warranty whatsoever.
If you lose data or your hair because of this program,
that's your problem.

=head1 CREDITS and THANKS

To Mattia Barbon for providing WxPerl.

The idea was taken from the Zenity project.

=cut



1;
