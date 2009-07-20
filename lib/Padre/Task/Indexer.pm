package Padre::Task::Indexer;

use strict;
use warnings;
use File::Find;
use Padre::Util;

use Padre::Task;
our @ISA = qw( Padre::Task );

use Padre::Wx ();


use Class::XSAccessor
	constructor => 'new',
	accessors => {
		index_class => 'index_class',
		index_args => 'index_args',
		runmode => 'runmode',
		directory_list => 'directory_list',
		match_regex   => 'match_regex',
	};

sub prepare {
	my $self = shift;
	
	my $PROGRESS_EVENT  : shared = Wx::NewEventType();
	$self->{PROGRESS_EVENT} = $PROGRESS_EVENT ;
	$self->task_warn( "Prepared $PROGRESS_EVENT" );
	
	if ( $self->{main_thread_only} ) {
		Wx::Event::EVT_COMMAND(
			Padre->ide->wx->main ,
		-1,
		$PROGRESS_EVENT,
		$self->{main_thread_only}{callback} ,
		);
		
	}
	
	return;
}

sub finish {
	my $self = shift;
	if ( $self->{main_thread_only} ) {	
		$self->{main_thread_only}{notify}->Destroy;
		
	
	}
	return 1;
	
}




sub run {
	my ($self) = shift;
	my $index_class = $self->index_class;
	eval "require $index_class" ;
	if ($@ ) {
		Padre::Util::debug "Failed to load $index_class : $@";
		return;
	}
	
	unless ( ref $self->index_args eq 'ARRAY' ) {
		Padre::Util::debug "index_args must be an arrayref";
		return;
	}
	my $index = $index_class->new( @{ $self->index_args } );
	
	my $files = $self->_find_files;
	Padre::Util::debug "Got files : " . @$files;
	
	
	my $idx = $index->indexer(  ( $self->runmode eq 'clobber' ) ? (clobber=>1) : () );
	my $total = scalar @$files;
	
	my $progress = 0;
	foreach my $file ( @$files ) {
		open( my $fh  , $file ) or die "Failed to open $file : $!";
		my $modified = (stat $file)[9];
		my $title = File::Basename::basename( $file );
		Padre::Util::debug "$title , modified $modified\n";
		#next; ## REMOVE ME
		my $content;
		{local $/;$content = <$fh>;}
		
		my $doc = {
			file => $file , modified => $modified , 
			title => $title ,
			content=> $content,
		};
		$idx->add_doc( $doc );
		$progress++;
		$self->post_event( $self->{PROGRESS_EVENT} , 
			sprintf( '%4f;%s' , (100*$progress/$total), $title)
		 );
	}
	$idx->commit;
	return;
}


use Data::Dumper;
sub _find_files {
	my $self = shift;
	my $dirs = $self->directory_list;
	my @files;
	Padre::Util::debug Dumper $dirs;
	File::Find::find( {
		wanted => sub {
			return unless $_ =~ /\.(pod|pm)$/;
			#$self->match_regex;
			push @files,$_;
		},
		no_chdir=>1 
	}, @$dirs );
	
	return \@files;
}

1;


