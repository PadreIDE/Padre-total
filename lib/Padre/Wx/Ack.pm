package Padre::Wx::Ack;
use strict;
use warnings;

use Wx                      qw(:everything);
use Wx::Event               qw(:everything);

our $VERSION = '0.07';

sub new {
    my ( $class, $win, $config ) = @_;
	my $id     = -1;
	my $title  = "Ack";
	my $pos    = wxDefaultPosition;
	my $size   = wxDefaultSize;
	my $name   = "";
	my $style = wxDEFAULT_FRAME_STYLE;

	my $dialog        = Wx::Dialog->new( $win, $id, $title, $pos, $size, $style, $name );
	my $label_1       = Wx::StaticText->new($dialog, -1, "Term: ", wxDefaultPosition, wxDefaultSize, );
	my $term          = Wx::ComboBox->new($dialog, -1, "", wxDefaultPosition, wxDefaultSize, [], wxCB_DROPDOWN);
	my $button_search = Wx::Button->new($dialog, wxID_FIND, '');
	my $label_2       = Wx::StaticText->new($dialog, -1, "Dir: ", wxDefaultPosition, wxDefaultSize, );
	my $dir           = Wx::ComboBox->new($dialog, -1, "", wxDefaultPosition, wxDefaultSize, [], wxCB_DROPDOWN);
	my $button_cancel = Wx::Button->new($dialog, wxID_CANCEL, '');
	my $nothing_1     = Wx::StaticText->new($dialog, -1, "", wxDefaultPosition, wxDefaultSize, );
	my $nothing_2     = Wx::StaticText->new($dialog, -1, "", wxDefaultPosition, wxDefaultSize, );
	my $button_dir    = Wx::Button->new($dialog, -1, "Pick directory");

    EVT_BUTTON( $dialog, $button_search, sub { $dialog->EndModal(wxID_FIND) } );
    EVT_BUTTON( $dialog, $button_dir,    sub { on_pick_dir($dir, @_) } );
    EVT_BUTTON( $dialog, $button_cancel, sub { $dialog->EndModal(wxID_CANCEL) } );

	#$dialog->SetTitle("frame_1");
	$term->SetSelection(-1);
	$dir->SetSelection(-1);

    # layout
	my $sizer_1 = Wx::BoxSizer->new(wxVERTICAL);
	my $grid_sizer_1 = Wx::GridSizer->new(4, 3, 0, 0);
	$grid_sizer_1->Add($label_1, 0, 0, 0);
	$grid_sizer_1->Add($term, 0, 0, 0);
	$grid_sizer_1->Add($button_search, 0, 0, 0);
	$grid_sizer_1->Add($label_2, 0, 0, 0);
	$grid_sizer_1->Add($dir, 0, 0, 0);
	$grid_sizer_1->Add($button_dir, 0, 0, 0);
	$grid_sizer_1->Add($nothing_1, 0, 0, 0);
	$grid_sizer_1->Add($nothing_2, 0, 0, 0);
	$grid_sizer_1->Add($button_cancel, 0, 0, 0);

	$sizer_1->Add($grid_sizer_1, 1, wxEXPAND, 0);

	$dialog->SetSizer($sizer_1);
	$sizer_1->Fit($dialog);
	$dialog->Layout();



    #$self->Show(1);
    if ($dialog->ShowModal == wxID_CANCEL) {
        return;
    }
    my %search;
    $search{term}  = $term->GetValue;

	return \%search;
}

sub on_pick_dir {
    my ($dir, $self, $event) = @_;

    my $dir_dialog = Wx::DirDialog->new( $self, "Select directory", '');
    if ($dir_dialog->ShowModal == wxID_CANCEL) {
        return;
    }
    $dir->SetValue($dir_dialog->GetPath);

    return;
}

1;

