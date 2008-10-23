package Padre::Wx::RightClick;

use 5.008;
use strict;
use warnings;

# Find and Replace widget of Padre

use Wx             qw(:everything);
use Wx::Event      qw(:everything);

our $VERSION = '0.12';

sub on_right_click {
	my ($self, $event) = @_;
#print "right\n";
	my @options = qw(abc def);
	my $HEIGHT = 30;
	my $dialog = Wx::Dialog->new( $self, -1, "", [-1, -1], [100, 50 + $HEIGHT * $#options], wxBORDER_SIMPLE);
	#$dialog->;
	foreach my $i (0..@options-1) {
		EVT_BUTTON( $dialog, Wx::Button->new( $dialog, -1, $options[$i], [10, 10+$HEIGHT*$i] ), sub {on_right(@_, $i)} );
	}
	my $ret = $dialog->Show;
#print "ret\n";
	#my $pop = Padre::Wx::Popup->new($self); #, wxSIMPLE_BORDER);
	#$pop->Move($event->GetPosition());
	#$pop->SetSize(300, 200);
	#$pop->Popup;

#Hide
#Destroy

	#my $choices = [ 'This', 'is one of my',  'really', 'wonderful', 'examples', ];
	#my $combo = Wx::BitmapComboBox->new($self,-1,"This",[2,2],[10,10],$choices );

	return;
}

sub on_right {
	my ($self, $event, $val) = @_;
#print "$self $event $val\n";
#print ">", $event->GetClientObject, "<\n";
	$self->Hide;
	$self->Destroy;

	return;
}


1;
