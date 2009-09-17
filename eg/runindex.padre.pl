use Padre::Service::Indexer;



use Padre::Wx ();
use Wx qw(:progressdialog);

my $dialog = Wx::ProgressDialog->new( 'DocBrowser index rebuild',
                                          'An informative message',
                                          100, Padre->ide->wx->main,
                                          wxPD_CAN_ABORT|wxPD_AUTO_HIDE|
                                          wxPD_SMOOTH|
                                          wxPD_ELAPSED_TIME|
                                          wxPD_ESTIMATED_TIME|
                                          wxPD_REMAINING_TIME );

$dialog->Update( 1 , 'starting indexer' );


my $update_progress = sub { 
	my $main = shift;
	my $event = shift;
	
	my $data = $event->GetData;
	warn  "update $data" ;
	my ($val,$info) = split /;/ , $data;
	
	if ( $dialog->Update( $val, $info ) ) {
	    return;
	}
	else {
            warn "Tried to cancel - good luck!";
	    $dialog->Destroy;
        } 
};





my $i = Padre::Service::Indexer->new(
	index_class => 'Padre::Index::Kinosearch',
	index_args=>[qw( index_directory /tmp/padre-index )],
	runmode => 'clobber',
	directory_list => [ @INC  ],
	match_regex=> qr/\.(pl|pm|pod)$/,
	
	main_thread_only => {
		notify => $dialog,
                callback => $update_progress,
        }
);

$i->schedule;

