package Padre::Plugin::Swarm::Wx::Preferences;

use strict;
use warnings;

use Wx qw[:everything];
use base qw(Wx::Dialog);
use strict;

our $VERSION = '0.08';

use Wx::Locale gettext => '_T';
sub new {
	my( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
	$parent = undef              unless defined $parent;
	$id     = -1                 unless defined $id;
	$title  = ""                 unless defined $title;
	$pos    = wxDefaultPosition  unless defined $pos;
	$size   = wxDefaultSize      unless defined $size;
	$name   = ""                 unless defined $name;

# begin wxGlade: wxDialog::new

	$style = wxDEFAULT_DIALOG_STYLE|wxRESIZE_BORDER 
		unless defined $style;

	$self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
	$self->{label_4} = Wx::StaticText->new($self, -1, _T("Swarm"), wxDefaultPosition, wxDefaultSize, );
	$self->{bitmap_1} = Wx::StaticBitmap->new($self, -1, Wx::Bitmap->new("/home/andrewb/dev/bleeding/Padre-Plugin-Swarm/share/icons/padre/128x128/status/padre-plugin-swarm.png", wxBITMAP_TYPE_ANY), wxDefaultPosition, wxDefaultSize, );
	$self->{label_2} = Wx::StaticText->new($self, -1, _T("Nickname"), wxDefaultPosition, wxDefaultSize, );
	$self->{text_ctrl_3} = Wx::TextCtrl->new($self, -1, "", wxDefaultPosition, wxDefaultSize, );
	$self->{label_3} = Wx::StaticText->new($self, -1, _T("Local Multicast"), wxDefaultPosition, wxDefaultSize, );
	$self->{checkbox_1} = Wx::CheckBox->new($self, -1, "", wxDefaultPosition, wxDefaultSize, );
	$self->{label_1} = Wx::StaticText->new($self, -1, _T("Multicast Address"), wxDefaultPosition, wxDefaultSize, );
	$self->{text_ctrl_1} = Wx::TextCtrl->new($self, -1, _T("239.255.255.1"), wxDefaultPosition, wxDefaultSize, );
	$self->{label_5} = Wx::StaticText->new($self, -1, _T("Global Server"), wxDefaultPosition, wxDefaultSize, );
	$self->{checkbox_2} = Wx::CheckBox->new($self, -1, "", wxDefaultPosition, wxDefaultSize, );
	$self->{label_6} = Wx::StaticText->new($self, -1, _T("Global Address"), wxDefaultPosition, wxDefaultSize, );
	$self->{text_ctrl_2} = Wx::TextCtrl->new($self, -1, _T("swarm.perlide.org"), wxDefaultPosition, wxDefaultSize, );
	$self->{button_2} = Wx::Button->new($self, wxID_OK, "");
	$self->{button_3} = Wx::Button->new($self, wxID_CANCEL, "");

	$self->__set_properties();
	$self->__do_layout();

# end wxGlade
	return $self;

}


sub __set_properties {
	my $self = shift;

# begin wxGlade: wxDialog::__set_properties

	$self->SetTitle(_T("Preferences"));
	$self->SetSize(Wx::Size->new(300, 400));
	$self->{label_4}->SetFont(Wx::Font->new(24, wxDEFAULT, wxNORMAL, wxBOLD, 0, ""));
	$self->{checkbox_1}->SetValue(1);
	$self->{text_ctrl_1}->SetToolTipString(_T("Multicast group address"));
	$self->{text_ctrl_2}->SetToolTipString(_T("Hostname of a swarm service provider"));
	$self->{text_ctrl_2}->Enable(0);

# end wxGlade
}

sub __do_layout {
	my $self = shift;

# begin wxGlade: wxDialog::__do_layout

	$self->{sizer_2} = Wx::BoxSizer->new(wxVERTICAL);
	$self->{sizer_3} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{grid_sizer_2} = Wx::FlexGridSizer->new(1, 2, 0, 8);
	$self->{grid_sizer_1} = Wx::FlexGridSizer->new(5, 2, 4, 6);
	$self->{sizer_2}->Add($self->{label_4}, 0, wxALIGN_CENTER_HORIZONTAL, 0);
	$self->{sizer_2}->Add($self->{bitmap_1}, 0, wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_1}->Add($self->{label_2}, 0, wxALIGN_RIGHT|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_1}->Add($self->{text_ctrl_3}, 0, wxEXPAND, 0);
	$self->{grid_sizer_1}->Add($self->{label_3}, 0, wxALIGN_RIGHT|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_1}->Add($self->{checkbox_1}, 0, 0, 0);
	$self->{grid_sizer_1}->Add($self->{label_1}, 0, wxALIGN_RIGHT|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_1}->Add($self->{text_ctrl_1}, 0, wxEXPAND, 0);
	$self->{grid_sizer_1}->Add($self->{label_5}, 0, wxALIGN_RIGHT|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_1}->Add($self->{checkbox_2}, 0, 0, 0);
	$self->{grid_sizer_1}->Add($self->{label_6}, 0, wxALIGN_RIGHT|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_1}->Add($self->{text_ctrl_2}, 0, wxEXPAND, 0);
	$self->{grid_sizer_1}->AddGrowableCol(1);
	$self->{sizer_2}->Add($self->{grid_sizer_1}, 1, wxEXPAND, 0);
	$self->{grid_sizer_2}->Add($self->{button_2}, 0, 0, 0);
	$self->{grid_sizer_2}->Add($self->{button_3}, 0, 0, 0);
	$self->{sizer_3}->Add($self->{grid_sizer_2}, 1, wxEXPAND, 0);
	$self->{sizer_2}->Add($self->{sizer_3}, 0, wxALIGN_RIGHT|wxALIGN_BOTTOM, 4);
	$self->SetSizer($self->{sizer_2});
	$self->Layout();
	
}


1;
