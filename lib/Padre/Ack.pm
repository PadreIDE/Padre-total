package Padre::Ack;

use strict;
use warnings;
use Wx        qw(:everything);
use Wx::Event qw(:everything);
use Padre::Wx::Ack;
use App::Ack;

my $iter;
my %opts;

our $VERSION = '0.07';

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


    my $search = Padre::Wx::Ack->new;
use Data::Dumper;
print Dumper $search;

    $search->{dir} ||= '.';
    return if not $search->{term};

    #my $config = get_config();
    #%opts;# = %{ $config->{opts} };
    #$opts{regex} = $regex;
    $opts{regex} = $search->{term};
    if (-f $search->{dir}) {
        $opts{all} = 1;
    }
    #$opts{after_context}  = 0;
    #$opts{before_context} = 0;
print Dumper \%opts;
    my $what = App::Ack::get_starting_points( [$search->{dir}], \%opts );
    fill_type_wanted();
#    $App::Ack::type_wanted{cc} = 1;
#    $opts{show_filename} = 1;
#    $opts{follow} = 0;
    $iter = App::Ack::get_iterator( $what, \%opts );
    App::Ack::filetype_setup();


    $self->show_output();

    EVT_COMMAND( $self, -1, $DONE_EVENT, \&ack_done );


    my $worker = threads->create( \&on_ack_thread );
    #my $data = Padre::Wx::Ack->new;
}
sub ack_done {
    my( $self, $event ) = @_;

   my $data = $event->GetData;
   #print "Data: $data\n";
   $self->{output}->AppendText("$data\n");

   return;
}

sub on_ack_thread {

    print "in thread\n";
    App::Ack::print_matches( $iter, \%opts );

}

sub print_results {
    my ($text) = @_;
print $text;
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
