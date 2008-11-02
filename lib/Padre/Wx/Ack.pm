package Padre::Wx::Ack;

use strict;
use warnings;
use Data::Dumper            qw(Dumper);

use App::Ack;

use Padre::Wx;

my $iter;
my %opts;

our $VERSION = '0.15';

{
	no warnings 'redefine';
	sub App::Ack::print_first_filename { print_results("$_[0]\n"); }
	sub App::Ack::print_separator      { print_results("--\n"); }
	sub App::Ack::print                { print_results($_[0]); }
	sub App::Ack::print_filename       { print_results("$_[0]$_[1]"); }
	sub App::Ack::print_line_no        { print_results("$_[0]$_[1]"); }
}

my $DONE_EVENT : shared = Wx::NewEventType;

sub on_ack {
	my ($self) = @_;
	@_ = (); # cargo cult or bug? see Wx::Thread / Creating new threads

	# TODO kill the thread before closing the application

	my $search = dialog();

	$search->{dir} ||= '.';
	return if not $search->{term};

	$opts{regex} = $search->{term};
	if (-f $search->{dir}) {
		$opts{all} = 1;
	}
	my $what = App::Ack::get_starting_points( [$search->{dir}], \%opts );
	fill_type_wanted();
	$iter = App::Ack::get_iterator( $what, \%opts );
	App::Ack::filetype_setup();

	$self->show_output(1);

	Wx::Event::EVT_COMMAND( $self, -1, $DONE_EVENT, \&ack_done );

	my $worker = threads->create( \&on_ack_thread );

	return;
}


sub dialog {
	my ( $win, $config ) = @_;
	my $id     = -1;
	my $title  = "Ack";
	my $pos    = Wx::wxDefaultPosition;
	my $size   = Wx::wxDefaultSize;
	my $name   = "";
	my $style = Wx::wxDEFAULT_FRAME_STYLE;

	my $dialog        = Wx::Dialog->new( $win, $id, $title, $pos, $size, $style, $name );
	my $label_1       = Wx::StaticText->new($dialog, -1, "Term: ", Wx::wxDefaultPosition, Wx::wxDefaultSize, );
	my $term          = Wx::ComboBox->new($dialog, -1, "", Wx::wxDefaultPosition, Wx::wxDefaultSize, [], Wx::wxCB_DROPDOWN);
	my $button_search = Wx::Button->new($dialog, Wx::wxID_FIND, '');
	my $label_2       = Wx::StaticText->new($dialog, -1, "Dir: ", Wx::wxDefaultPosition, Wx::wxDefaultSize, );
	my $dir           = Wx::ComboBox->new($dialog, -1, "", Wx::wxDefaultPosition, Wx::wxDefaultSize, [], Wx::wxCB_DROPDOWN);
	my $button_cancel = Wx::Button->new($dialog, Wx::wxID_CANCEL, '');
	my $nothing_1     = Wx::StaticText->new($dialog, -1, "", Wx::wxDefaultPosition, Wx::wxDefaultSize, );
	my $nothing_2     = Wx::StaticText->new($dialog, -1, "", Wx::wxDefaultPosition, Wx::wxDefaultSize, );
	my $button_dir    = Wx::Button->new($dialog, -1, "Pick &directory");

	Wx::Event::EVT_BUTTON( $dialog, $button_search, sub { $dialog->EndModal(Wx::wxID_FIND) } );
	Wx::Event::EVT_BUTTON( $dialog, $button_dir,    sub { on_pick_dir($dir, @_) } );
	Wx::Event::EVT_BUTTON( $dialog, $button_cancel, sub { $dialog->EndModal(Wx::wxID_CANCEL) } );

	#$dialog->SetTitle("frame_1");
	$term->SetSelection(-1);
	$dir->SetSelection(-1);
	$button_search->SetDefault;

	# layout
	my $sizer_1 = Wx::BoxSizer->new(Wx::wxVERTICAL);
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

	$sizer_1->Add($grid_sizer_1, 1, Wx::wxEXPAND, 0);

	$dialog->SetSizer($sizer_1);
	$sizer_1->Fit($dialog);
	$dialog->Layout();

	$term->SetFocus;
	my $ret = $dialog->ShowModal;

	if ($ret == Wx::wxID_CANCEL) {
		 $dialog->Destroy;
		return;
	}
	
	my %search;
	$search{term}  = $term->GetValue;
	$search{dir}   = $dir->GetValue;
	$dialog->Destroy;
 
	return \%search;
}

sub on_pick_dir {
	my ($dir, $self, $event) = @_;

	my $dir_dialog = Wx::DirDialog->new( $self, "Select directory", '');
	if ($dir_dialog->ShowModal == Wx::wxID_CANCEL) {
		return;
	}
	$dir->SetValue($dir_dialog->GetPath);

	return;
}



sub ack_done {
	my( $self, $event ) = @_;

   my $data = $event->GetData;
   #print "Data: $data\n";
   $self->{output}->AppendText("$data\n");

   return;
}

sub on_ack_thread {
	App::Ack::print_matches( $iter, \%opts );
}

sub print_results {
	my ($text) = @_;
#print $text;
	#my $end = $result->get_end_iter;
	#$result->insert($end, $text);

	my $frame = Padre->ide->wx->main_window;
	my $threvent = Wx::PlThreadEvent->new( -1, $DONE_EVENT, $text );
	Wx::PostEvent( $frame, $threvent );


	return;
}



# see t/module.t in ack distro
sub fill_type_wanted {
	for my $i ( App::Ack::filetypes_supported() ) {
		$App::Ack::type_wanted{ $i } = undef;
	}
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
